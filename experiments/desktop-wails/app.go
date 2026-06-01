package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/atotto/clipboard"
)

type ClipItem struct {
	ID        string `json:"id"`
	Text      string `json:"text"`
	Pinned    bool   `json:"pinned"`
	Source    string `json:"source"`
	CreatedAt int64  `json:"createdAt"`
}

type NoteItem struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Body      string `json:"body"`
	Color     string `json:"color"`
	Pinned    bool   `json:"pinned"`
	CreatedAt int64  `json:"createdAt"`
	UpdatedAt int64  `json:"updatedAt"`
}

type persistedState struct {
	Paused   bool       `json:"paused"`
	Items    []ClipItem `json:"items"`
	ShelfIDs []string   `json:"shelfIds"`
	Notes    []NoteItem `json:"notes"`
}

type AppState struct {
	Paused bool       `json:"paused"`
	Items  []ClipItem `json:"items"`
	Shelf  []ClipItem `json:"shelf"`
	Notes  []NoteItem `json:"notes"`
}

type App struct {
	ctx       context.Context
	mu        sync.RWMutex
	items     []ClipItem
	shelfIDs  []string
	notes     []NoteItem
	paused    bool
	lastValue string
	dataPath  string
	maxItems  int
}

func NewApp() *App { return &App{maxItems: 500} }

func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
	if err := a.initDataPath(); err == nil {
		_ = a.loadState()
	}
	go a.clipboardLoop(ctx)
}

func (a *App) initDataPath() error {
	cfgDir, err := os.UserConfigDir()
	if err != nil {
		return err
	}
	appDir := filepath.Join(cfgDir, "pkbrain")
	if err := os.MkdirAll(appDir, 0o755); err != nil {
		return err
	}
	a.dataPath = filepath.Join(appDir, "state.json")
	return nil
}

func (a *App) clipboardLoop(ctx context.Context) {
	ticker := time.NewTicker(700 * time.Millisecond)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			a.captureClipboardText()
		}
	}
}

func (a *App) captureClipboardText() {
	a.mu.RLock()
	paused := a.paused
	a.mu.RUnlock()
	if paused {
		return
	}

	text, err := clipboard.ReadAll()
	if err != nil {
		return
	}
	trimmed := strings.TrimSpace(text)
	if trimmed == "" {
		return
	}

	a.mu.Lock()
	defer a.mu.Unlock()
	if trimmed == a.lastValue {
		return
	}
	a.lastValue = trimmed
	if len(a.items) > 0 && a.items[0].Text == trimmed {
		return
	}

	item := ClipItem{ID: fmt.Sprintf("%d", time.Now().UnixNano()), Text: trimmed, Source: "unknown", CreatedAt: time.Now().Unix()}
	a.items = append([]ClipItem{item}, a.items...)
	if len(a.items) > a.maxItems {
		a.items = a.items[:a.maxItems]
	}
	a.pruneShelfLocked()
	_ = a.saveStateLocked()
}

func (a *App) GetState() AppState {
	a.mu.RLock()
	defer a.mu.RUnlock()
	return a.buildStateLocked()
}

func (a *App) TogglePause() AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.paused = !a.paused
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) TogglePin(id string) (AppState, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	for i := range a.items {
		if a.items[i].ID == id {
			a.items[i].Pinned = !a.items[i].Pinned
			_ = a.saveStateLocked()
			return a.buildStateLocked(), nil
		}
	}
	return AppState{}, errors.New("clip not found")
}

func (a *App) DeleteClip(id string) AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	next := make([]ClipItem, 0, len(a.items))
	for _, item := range a.items {
		if item.ID != id {
			next = append(next, item)
		}
	}
	a.items = next
	a.pruneShelfLocked()
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) ClearUnpinned() AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	next := make([]ClipItem, 0, len(a.items))
	for _, item := range a.items {
		if item.Pinned {
			next = append(next, item)
		}
	}
	a.items = next
	a.pruneShelfLocked()
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) AddToShelf(id string) (AppState, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if !a.hasItemLocked(id) {
		return AppState{}, errors.New("clip not found")
	}
	for _, shelfID := range a.shelfIDs {
		if shelfID == id {
			return a.buildStateLocked(), nil
		}
	}
	a.shelfIDs = append(a.shelfIDs, id)
	_ = a.saveStateLocked()
	return a.buildStateLocked(), nil
}

func (a *App) RemoveFromShelf(id string) AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	next := make([]string, 0, len(a.shelfIDs))
	for _, shelfID := range a.shelfIDs {
		if shelfID != id {
			next = append(next, shelfID)
		}
	}
	a.shelfIDs = next
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) ClearShelf() AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.shelfIDs = []string{}
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) CopyShelf() error {
	a.mu.RLock()
	defer a.mu.RUnlock()
	if len(a.shelfIDs) == 0 {
		return nil
	}
	parts := make([]string, 0, len(a.shelfIDs))
	for _, id := range a.shelfIDs {
		if item, ok := a.findItemLocked(id); ok {
			parts = append(parts, item.Text)
		}
	}
	return clipboard.WriteAll(strings.Join(parts, "\n"))
}

func (a *App) CopyClip(id string) error {
	a.mu.RLock()
	defer a.mu.RUnlock()
	item, ok := a.findItemLocked(id)
	if !ok {
		return errors.New("clip not found")
	}
	return clipboard.WriteAll(item.Text)
}

func (a *App) CreateNote(title string, body string, color string) AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	now := time.Now().Unix()
	n := NoteItem{
		ID:        fmt.Sprintf("note_%d", time.Now().UnixNano()),
		Title:     strings.TrimSpace(title),
		Body:      strings.TrimSpace(body),
		Color:     normalizeColor(color),
		CreatedAt: now,
		UpdatedAt: now,
	}
	if n.Title == "" {
		n.Title = "Untitled"
	}
	a.notes = append([]NoteItem{n}, a.notes...)
	a.sortNotesLocked()
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) UpdateNote(id string, title string, body string, color string) (AppState, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	for i := range a.notes {
		if a.notes[i].ID == id {
			a.notes[i].Title = strings.TrimSpace(title)
			a.notes[i].Body = strings.TrimSpace(body)
			a.notes[i].Color = normalizeColor(color)
			a.notes[i].UpdatedAt = time.Now().Unix()
			if a.notes[i].Title == "" {
				a.notes[i].Title = "Untitled"
			}
			a.sortNotesLocked()
			_ = a.saveStateLocked()
			return a.buildStateLocked(), nil
		}
	}
	return AppState{}, errors.New("note not found")
}

func (a *App) DeleteNote(id string) AppState {
	a.mu.Lock()
	defer a.mu.Unlock()
	next := make([]NoteItem, 0, len(a.notes))
	for _, n := range a.notes {
		if n.ID != id {
			next = append(next, n)
		}
	}
	a.notes = next
	_ = a.saveStateLocked()
	return a.buildStateLocked()
}

func (a *App) TogglePinNote(id string) (AppState, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	for i := range a.notes {
		if a.notes[i].ID == id {
			a.notes[i].Pinned = !a.notes[i].Pinned
			a.notes[i].UpdatedAt = time.Now().Unix()
			a.sortNotesLocked()
			_ = a.saveStateLocked()
			return a.buildStateLocked(), nil
		}
	}
	return AppState{}, errors.New("note not found")
}

func (a *App) sortNotesLocked() {
	sort.SliceStable(a.notes, func(i, j int) bool {
		if a.notes[i].Pinned == a.notes[j].Pinned {
			return a.notes[i].UpdatedAt > a.notes[j].UpdatedAt
		}
		return a.notes[i].Pinned
	})
}

func normalizeColor(color string) string {
	switch strings.ToLower(strings.TrimSpace(color)) {
	case "yellow", "pink", "blue", "green", "orange", "purple":
		return strings.ToLower(strings.TrimSpace(color))
	default:
		return "yellow"
	}
}

func (a *App) buildStateLocked() AppState {
	items := a.sortedItemsLocked()
	shelf := make([]ClipItem, 0, len(a.shelfIDs))
	for _, id := range a.shelfIDs {
		if item, ok := a.findItemLocked(id); ok {
			shelf = append(shelf, item)
		}
	}
	notes := make([]NoteItem, len(a.notes))
	copy(notes, a.notes)
	return AppState{Paused: a.paused, Items: items, Shelf: shelf, Notes: notes}
}

func (a *App) sortedItemsLocked() []ClipItem {
	items := make([]ClipItem, len(a.items))
	copy(items, a.items)
	sort.SliceStable(items, func(i, j int) bool {
		if items[i].Pinned == items[j].Pinned {
			return items[i].CreatedAt > items[j].CreatedAt
		}
		return items[i].Pinned
	})
	return items
}

func (a *App) hasItemLocked(id string) bool {
	_, ok := a.findItemLocked(id)
	return ok
}

func (a *App) findItemLocked(id string) (ClipItem, bool) {
	for _, item := range a.items {
		if item.ID == id {
			return item, true
		}
	}
	return ClipItem{}, false
}

func (a *App) pruneShelfLocked() {
	valid := make(map[string]struct{}, len(a.items))
	for _, item := range a.items {
		valid[item.ID] = struct{}{}
	}
	next := make([]string, 0, len(a.shelfIDs))
	for _, id := range a.shelfIDs {
		if _, ok := valid[id]; ok {
			next = append(next, id)
		}
	}
	a.shelfIDs = next
}

func (a *App) saveStateLocked() error {
	if a.dataPath == "" {
		return nil
	}
	payload, err := json.MarshalIndent(persistedState{Paused: a.paused, Items: a.items, ShelfIDs: a.shelfIDs, Notes: a.notes}, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(a.dataPath, payload, 0o644)
}

func (a *App) loadState() error {
	raw, err := os.ReadFile(a.dataPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	var state persistedState
	if err := json.Unmarshal(raw, &state); err != nil {
		return err
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	a.paused = state.Paused
	a.items = state.Items
	a.shelfIDs = state.ShelfIDs
	a.notes = state.Notes
	a.pruneShelfLocked()
	a.sortNotesLocked()
	if len(a.items) > 0 {
		a.lastValue = a.items[0].Text
	}
	return nil
}

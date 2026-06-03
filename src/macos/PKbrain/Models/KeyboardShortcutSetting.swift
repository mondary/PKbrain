import AppKit
import Carbon.HIToolbox
import Foundation

enum ShortcutModifierPreset: String, CaseIterable, Codable, Identifiable {
    case shift
    case control
    case option
    case controlShift
    case controlOption
    case optionShift
    case command
    case commandShift
    case commandOption
    case commandControl
    case commandControlShift
    case commandControlOption
    case commandOptionShift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shift: localizedString("modifier_shift")
        case .control: "Control"
        case .option: "Option"
        case .controlShift: localizedString("modifier_control_shift")
        case .controlOption: "Control + Option"
        case .optionShift: "Option + Shift"
        case .command: localizedString("modifier_command")
        case .commandShift: localizedString("modifier_command_shift")
        case .commandOption: localizedString("modifier_command_option")
        case .commandControl: localizedString("modifier_command_control")
        case .commandControlShift: "Command + Control + Shift"
        case .commandControlOption: "Command + Control + Option"
        case .commandOptionShift: localizedString("modifier_command_option_shift")
        }
    }

    var symbolPrefix: String {
        switch self {
        case .shift: "⇧"
        case .control: "⌃"
        case .option: "⌥"
        case .controlShift: "⌃⇧"
        case .controlOption: "⌃⌥"
        case .optionShift: "⌥⇧"
        case .command: "⌘"
        case .commandShift: "⇧⌘"
        case .commandOption: "⌥⌘"
        case .commandControl: "⌃⌘"
        case .commandControlShift: "⌃⇧⌘"
        case .commandControlOption: "⌃⌥⌘"
        case .commandOptionShift: "⌥⇧⌘"
        }
    }

    var flags: NSEvent.ModifierFlags {
        switch self {
        case .shift: [.shift]
        case .control: [.control]
        case .option: [.option]
        case .controlShift: [.control, .shift]
        case .controlOption: [.control, .option]
        case .optionShift: [.option, .shift]
        case .command: [.command]
        case .commandShift: [.command, .shift]
        case .commandOption: [.command, .option]
        case .commandControl: [.command, .control]
        case .commandControlShift: [.command, .control, .shift]
        case .commandControlOption: [.command, .control, .option]
        case .commandOptionShift: [.command, .option, .shift]
        }
    }

    var carbonFlags: UInt32 {
        switch self {
        case .shift: return UInt32(shiftKey)
        case .control: return UInt32(controlKey)
        case .option: return UInt32(optionKey)
        case .controlShift: return UInt32(controlKey | shiftKey)
        case .controlOption: return UInt32(controlKey | optionKey)
        case .optionShift: return UInt32(optionKey | shiftKey)
        case .command: return UInt32(cmdKey)
        case .commandShift: return UInt32(cmdKey | shiftKey)
        case .commandOption: return UInt32(cmdKey | optionKey)
        case .commandControl: return UInt32(cmdKey | controlKey)
        case .commandControlShift: return UInt32(cmdKey | controlKey | shiftKey)
        case .commandControlOption: return UInt32(cmdKey | controlKey | optionKey)
        case .commandOptionShift: return UInt32(cmdKey | optionKey | shiftKey)
        }
    }
}

struct KeyboardShortcutSetting: Codable, Equatable {
    var key: String
    var modifier: ShortcutModifierPreset

    var normalizedKey: String {
        switch key {
        case "delete": "\u{8}"
        case "space": " "
        default: key.lowercased()
        }
    }

    var displayValue: String {
        let label: String
        switch normalizedKey {
        case "\u{8}": label = "⌫"
        case " ": label = "Space"
        default: label = normalizedKey.uppercased()
        }
        return "\(modifier.symbolPrefix)\(label)"
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case focusLastNoteGlobal
    case newNoteGlobal
    case newStickyNote
    case showAllNotes
    case showNotesList
    case showClipboardWindow
    case saveAllNotes
    case preferences
    case closeNoteWindow
    case deleteStickyNote
    case toggleList
    case emojiSymbols
    case toggleMonospace
    case zoomIn
    case zoomOut
    case actualSize
    case windowLeftHalf
    case windowRightHalf
    case windowTopHalf
    case windowBottomHalf
    case windowMaximize
    case windowCenter
    case windowTopLeft
    case windowTopRight
    case windowBottomLeft
    case windowBottomRight
    case windowFirstThird
    case windowCenterThird
    case windowLastThird
    case windowNextDisplay
    case windowPreviousDisplay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focusLastNoteGlobal: localizedString("shortcut_focus_last_note_global")
        case .newNoteGlobal: localizedString("shortcut_create_new_note_global")
        case .newStickyNote: localizedString("new_sticky_note")
        case .showAllNotes: localizedString("show_all_notes")
        case .showNotesList: localizedString("show_notes_list")
        case .showClipboardWindow: localizedString("show_clipboard_window")
        case .saveAllNotes: localizedString("save_all_notes")
        case .preferences: localizedString("preferences")
        case .closeNoteWindow: localizedString("close_note_window")
        case .deleteStickyNote: localizedString("delete_sticky_note")
        case .toggleList: localizedString("toggle_list")
        case .emojiSymbols: localizedString("emoji_symbols")
        case .toggleMonospace: localizedString("toggle_monospace")
        case .zoomIn: localizedString("zoom_in")
        case .zoomOut: localizedString("zoom_out")
        case .actualSize: localizedString("actual_size")
        case .windowLeftHalf: localizedString("window_left_half")
        case .windowRightHalf: localizedString("window_right_half")
        case .windowTopHalf: localizedString("window_top_half")
        case .windowBottomHalf: localizedString("window_bottom_half")
        case .windowMaximize: localizedString("window_maximize")
        case .windowCenter: localizedString("window_center")
        case .windowTopLeft: localizedString("window_top_left")
        case .windowTopRight: localizedString("window_top_right")
        case .windowBottomLeft: localizedString("window_bottom_left")
        case .windowBottomRight: localizedString("window_bottom_right")
        case .windowFirstThird: localizedString("window_first_third")
        case .windowCenterThird: localizedString("window_center_third")
        case .windowLastThird: localizedString("window_last_third")
        case .windowNextDisplay: localizedString("window_next_display")
        case .windowPreviousDisplay: localizedString("window_previous_display")
        }
    }

    var group: String {
        switch self {
        case .focusLastNoteGlobal, .newNoteGlobal, .newStickyNote, .showAllNotes, .showNotesList, .showClipboardWindow, .saveAllNotes, .preferences:
            localizedString("shortcut_group_app")
        case .closeNoteWindow, .deleteStickyNote, .toggleList, .emojiSymbols, .toggleMonospace, .zoomIn, .zoomOut, .actualSize:
            localizedString("shortcut_group_note")
        case .windowLeftHalf, .windowRightHalf, .windowTopHalf, .windowBottomHalf, .windowMaximize, .windowCenter,
             .windowTopLeft, .windowTopRight, .windowBottomLeft, .windowBottomRight,
             .windowFirstThird, .windowCenterThird, .windowLastThird, .windowNextDisplay, .windowPreviousDisplay:
            localizedString("shortcut_group_window")
        }
    }

    var defaultShortcut: KeyboardShortcutSetting {
        switch self {
        // Avoid Shift+Space: too easy to trigger while typing.
        // Keep global shortcuts close to each other without conflicting with common macOS shortcuts.
        // Cmd+Shift+Space: focus last note
        // Ctrl+Shift+Space: create new note
        case .focusLastNoteGlobal: KeyboardShortcutSetting(key: "space", modifier: .commandShift)
        case .newNoteGlobal: KeyboardShortcutSetting(key: "space", modifier: .controlShift)
        case .newStickyNote: KeyboardShortcutSetting(key: "n", modifier: .command)
        case .showAllNotes: KeyboardShortcutSetting(key: "l", modifier: .shift)
        case .showNotesList: KeyboardShortcutSetting(key: "l", modifier: .commandShift)
        case .showClipboardWindow: KeyboardShortcutSetting(key: "v", modifier: .commandOption)
        case .saveAllNotes: KeyboardShortcutSetting(key: "s", modifier: .command)
        case .preferences: KeyboardShortcutSetting(key: ",", modifier: .command)
        case .closeNoteWindow: KeyboardShortcutSetting(key: "w", modifier: .command)
        case .deleteStickyNote: KeyboardShortcutSetting(key: "delete", modifier: .command)
        case .toggleList: KeyboardShortcutSetting(key: "l", modifier: .commandShift)
        case .emojiSymbols: KeyboardShortcutSetting(key: "space", modifier: .commandControl)
        case .toggleMonospace: KeyboardShortcutSetting(key: "m", modifier: .command)
        case .zoomIn: KeyboardShortcutSetting(key: "+", modifier: .command)
        case .zoomOut: KeyboardShortcutSetting(key: "-", modifier: .command)
        case .actualSize: KeyboardShortcutSetting(key: "0", modifier: .command)
        case .windowLeftHalf: KeyboardShortcutSetting(key: "h", modifier: .controlOption)
        case .windowRightHalf: KeyboardShortcutSetting(key: "l", modifier: .controlOption)
        case .windowTopHalf: KeyboardShortcutSetting(key: "k", modifier: .controlOption)
        case .windowBottomHalf: KeyboardShortcutSetting(key: "j", modifier: .controlOption)
        case .windowMaximize: KeyboardShortcutSetting(key: "m", modifier: .controlOption)
        case .windowCenter: KeyboardShortcutSetting(key: "c", modifier: .controlOption)
        case .windowTopLeft: KeyboardShortcutSetting(key: "u", modifier: .controlOption)
        case .windowTopRight: KeyboardShortcutSetting(key: "i", modifier: .controlOption)
        case .windowBottomLeft: KeyboardShortcutSetting(key: "n", modifier: .controlOption)
        case .windowBottomRight: KeyboardShortcutSetting(key: "o", modifier: .controlOption)
        case .windowFirstThird: KeyboardShortcutSetting(key: "1", modifier: .controlOption)
        case .windowCenterThird: KeyboardShortcutSetting(key: "2", modifier: .controlOption)
        case .windowLastThird: KeyboardShortcutSetting(key: "3", modifier: .controlOption)
        case .windowNextDisplay: KeyboardShortcutSetting(key: "]", modifier: .controlOption)
        case .windowPreviousDisplay: KeyboardShortcutSetting(key: "[", modifier: .controlOption)
        }
    }
}

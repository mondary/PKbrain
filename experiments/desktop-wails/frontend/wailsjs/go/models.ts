export namespace main {
	
	export class NoteItem {
	    id: string;
	    title: string;
	    body: string;
	    color: string;
	    pinned: boolean;
	    createdAt: number;
	    updatedAt: number;
	
	    static createFrom(source: any = {}) {
	        return new NoteItem(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.title = source["title"];
	        this.body = source["body"];
	        this.color = source["color"];
	        this.pinned = source["pinned"];
	        this.createdAt = source["createdAt"];
	        this.updatedAt = source["updatedAt"];
	    }
	}
	export class ClipItem {
	    id: string;
	    text: string;
	    pinned: boolean;
	    source: string;
	    createdAt: number;
	
	    static createFrom(source: any = {}) {
	        return new ClipItem(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.text = source["text"];
	        this.pinned = source["pinned"];
	        this.source = source["source"];
	        this.createdAt = source["createdAt"];
	    }
	}
	export class AppState {
	    paused: boolean;
	    items: ClipItem[];
	    shelf: ClipItem[];
	    notes: NoteItem[];
	
	    static createFrom(source: any = {}) {
	        return new AppState(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.paused = source["paused"];
	        this.items = this.convertValues(source["items"], ClipItem);
	        this.shelf = this.convertValues(source["shelf"], ClipItem);
	        this.notes = this.convertValues(source["notes"], NoteItem);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	

}


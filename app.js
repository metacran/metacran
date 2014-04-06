var couchapp = require('couchapp')
, path = require('path');

// Views
// =====
//
// A view corresponds to a subset of the records, and a type of ordering,
// essentially. E.g. one can get the same final data if a view returns
// documents, and these are taken apart by the list function, or if
// the view returns each version of the package separately. But the
// ordering will be different in both cases.
//
// We have the following views:
// - packages, all package documents, ordered by package name
// - active, active (non-archived) package documents, ordered by 
//   release date
// - pkgreleases, package versions, ordered by release date
// - archivals, last package versions for archived packages,
//   ordered by archival date
// - events, package events, ordered by event date
// - releases, R releases, ordered by date
// - release, packages and their versions for each R release

// Lists
// =====
//
// A list is a transformation of a view, e.g. taking out one specific
// version, or specific fields. A list has an input format and an
// output format.
// 
// We have the following lists:
// - id, put rows in an dictionary, use key as key
// - id1, put rows in an dictionary, use key[1] as key
// - il, put rows in a list

// API
// ===

ddoc = {
    _id: '_design/app'
    , views: {}
    , lists: {}
    , shows: {}
    , rewrites: 
    [ { from: "/", to: "../.." }
    , { from: '/-/all', to: '_list/id/active' }
    , { from: '/-/allall', to: '_list/id/packages' }
    , { from: '/-/pkgreleases', to: '_list/il/pkgreleases' }
    , { from: '/-/archivals', to: '_list/il/archivals' }
    , { from: '/-/events', to: '_list/il/events' }
    , { from: '/-/releases', to: '_list/il/releases' }
    , { from: '/-/release/:version', to: '_list/id1/release', 
        query: { "start_key":[":version"], 
		 "end_key":[":version",{}] } }
    , { from: '/:pkg', to: '_show/package/:pkg' }
    , { from: '/:pkg/:version', to: '_show/package/:pkg' }
    ]
};

module.exports = ddoc;

ddoc.views.packages = {
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	emit(doc._id, doc)
    }
}

ddoc.views.active = { 
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	if (!doc.archived) { emit(doc._id, doc); }
    }
}

ddoc.views.pkgreleases = {
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	for (var t in doc.timeline) {
	    if (doc.timeline && doc.timeline[t] != "Invalid date" &&
		t != "archived") {
		emit(doc.timeline[t], 
		     { "date": doc.timeline[t], "name": doc.name,
		       "package": doc.versions[t] })
	    }
	}
    }
}

ddoc.views.events = {
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	for (var t in doc.timeline) {
	    if (doc.timeline && doc.timeline[t] != "Invalid date") {
		var ev = t === "archived" ? "archived" : "released"
		var ver = t
		if (ver === "archived") ver=doc.latest		    
		emit(doc.timeline[t], 
		     { "date": doc.timeline[t], "name": doc.name, "event": ev,
		       "package": doc.versions[ver] })
	    }
	}
    }
}

ddoc.views.archivals = {
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	if (doc.archived) {
	    emit(doc.timeline['archived'], 
		 { "date": doc.archived_date, "name": doc.name, 
		   "comment": doc.archived_comment, 
		   "package": doc.versions[doc.latest] })
	}
    }
}

ddoc.views.releases = {
    map: function(doc) {
	if (!doc.type || doc.type != "release") return
	emit(doc.date, { version: doc._id, date: doc.date })
    }
}

ddoc.views.release = {
    map: function(doc) {
	if (doc.type && doc.type != "package") return
	if (!doc.versions) return
	for (var i in doc.versions) {
	    var v=doc.versions[i]
	    var r=v.releases
	    for (var j in v.releases) {
		emit([r[j], doc.name], i)
	    }
	}
    }
}

ddoc.lists.il = function(doc, req) {
    var row, first=true
    send('[ ')
    while (row = getRow()) {
	if (!row.id) continue
	if (first) first=false; else send(",")
	send(JSON.stringify(row.value))
    }
    send(" ]")
}

ddoc.lists.id = function(doc, req) {
    var row, first=true
    send('{ ')
    while (row = getRow()) {
	if (!row.id) continue
	if (first) first=false; else send(",")
	send(JSON.stringify(row.key) + ":" + JSON.stringify(row.value))
    }
    send(" }")
}

ddoc.lists.id1 = function(doc, req) {
    var row, first=true
    send('{ ')
    while (row = getRow()) {
	if (!row.id) continue
	if (first) first=false; else send(",")
	send(JSON.stringify(row.key[1]) + ":" + JSON.stringify(row.value))
    }
    send(" }")
}

ddoc.shows.package = function(doc, req) {

    var code = 200
      , headers = {"Content-Type":"application/json"}
      , body = null
    
    var ver = req.query.version
    if (!req.query.version) ver = doc.latest
    if (ver != "all") {
	body = doc.versions[ver]
	if (!body) {
	    code = 404
	    body = {"error" : "version not found: " + req.query.version}
	}
    } else {
	body = doc
	delete body._revisions
    }
    
    body = req.query.jsonp
	? req.query.jsonp + "(" + JSON.stringify(body) + ")"
	: toJSON(body)

    return { code : code, body : body, headers : headers }
}

ddoc.validate_doc_update = function(newDoc, oldDoc, userCtx) {
    if ((userCtx.roles.indexOf('_admin') === -1)) { 
	throw({unauthorized: 'Only admins may create/edit documents.'}); 
    }
}

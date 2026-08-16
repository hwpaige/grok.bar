function emptyState() {
  return {
    runningSessions: 0,
    runningAgents: 0,
    grokSessions: [],
    cursorSessions: [],
    sessions: []
  }
}

function asList(value) {
  return Array.isArray(value) ? value : []
}

function parseSessions(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    if (!data || typeof data !== "object") return emptyState()
    var grok = asList(data.grokSessions)
    var cursor = asList(data.cursorSessions)
    var combined = asList(data.sessions)
    if (!grok.length && !cursor.length && combined.length) {
      for (var i = 0; i < combined.length; i++) {
        var row = combined[i] || {}
        if (row.provider === "cursor")
          cursor.push(row)
        else
          grok.push(row)
      }
    }
    if (!combined.length)
      combined = grok.concat(cursor)
    return {
      runningSessions: Number(data.runningSessions || combined.length || 0),
      runningAgents: Number(data.runningAgents || 0),
      grokSessions: grok,
      cursorSessions: cursor,
      sessions: combined
    }
  } catch (e) {
    return emptyState()
  }
}

function badgeText(count) {
  var n = Number(count || 0)
  if (!isFinite(n) || n <= 0) return ""
  return n > 9 ? "9+" : String(Math.round(n))
}

function summaryLine(state) {
  var grok = asList(state && state.grokSessions).length
  var cursor = asList(state && state.cursorSessions).length
  var agents = Number(state && state.runningAgents || 0)
  var parts = []
  if (cursor > 0) {
    parts.push(grok + " grok")
    parts.push(cursor + " cursor")
  } else {
    parts.push(grok + " " + (grok === 1 ? "session" : "sessions"))
  }
  parts.push(agents + " " + (agents === 1 ? "agent" : "agents"))
  return parts.join(" · ")
}

function statusColor(status, foreground, urgent) {
  if (status === "active") return "#3daa5c"
  if (status === "waiting") return "#d4a017"
  if (status === "error") return urgent || "#e5534b"
  if (status === "blocked") return "#d1862b"
  return Qt.darker(foreground || "#888888", 1.7)
}

function contextPercent(session) {
  var n = Number(session && session.contextPercent || 0)
  if (!isFinite(n) || n < 0) return 0
  if (n > 100) return 100
  return n
}

function contextColor(percent, foreground, urgent) {
  var n = Number(percent || 0)
  if (n >= 90) return urgent || "#e5534b"
  if (n >= 70) return "#d4a017"
  return "#3daa5c"
}

function contextPercentLabel(session) {
  if (!session) return ""
  if (Number(session.contextLimit || 0) <= 0 && contextPercent(session) <= 0)
    return ""
  return Math.round(contextPercent(session)) + "%"
}

function sessionDetail(session) {
  var status = session && session.statusLabel ? String(session.statusLabel) : "Idle"
  var usage = session && session.contextLabel ? String(session.contextLabel) : (session && session.tokensLabel ? String(session.tokensLabel) : "0")
  var agents = Number(session && session.agents || 0)
  var agentWord = agents === 1 ? "agent" : "agents"
  var place = session && session.cwdName ? String(session.cwdName) : ""
  var parts = [status, usage, agents + " " + agentWord]
  if (session && session.provider === "cursor" && place)
    parts.push(place)
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    emptyState: emptyState,
    parseSessions: parseSessions,
    badgeText: badgeText,
    summaryLine: summaryLine,
    statusColor: statusColor,
    contextPercent: contextPercent,
    contextColor: contextColor,
    contextPercentLabel: contextPercentLabel,
    sessionDetail: sessionDetail
  }
}

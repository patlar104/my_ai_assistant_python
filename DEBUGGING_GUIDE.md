# Comprehensive Debugging System Guide

## Overview

The application now includes a comprehensive debugging system that tracks **all user interactions, errors, state changes, and data flows**. This makes it possible to identify bugs that were previously invisible because they weren't being logged.

## Architecture

### Centralized Debug Logger (`lib/utils/debug_logger.dart`)

A single utility class that provides:
- **Efficient append-only logging** (no file reading, prevents performance issues)
- **Structured JSON logs** with consistent format
- **Automatic session tracking** for grouping related events
- **Categorized logging** (user_interaction, error, state_change, data_flow, etc.)

### Log Categories

1. **User Interactions** (`user_interaction`)
   - Button clicks
   - Icon taps
   - Text input submissions
   - Settings changes

2. **Errors** (`error`)
   - Exceptions in UI callbacks
   - API failures
   - Storage errors

3. **State Changes** (`state_change`)
   - Loading state toggles
   - Settings panel visibility
   - Conversation selection

4. **Data Flow** (`data_flow`)
   - API responses
   - Storage operations
   - Message additions

5. **Navigation** (`navigation`)
   - Route changes
   - Screen transitions

6. **Dialogs** (`dialog`)
   - Dialog opens/closes
   - User confirmations/cancellations

7. **Performance** (`performance`)
   - Operation durations
   - Performance metrics

## Instrumented User Interactions

### Chat View
- ✅ Send message button click
- ✅ Text field submission (Enter key)
- ✅ Regenerate response button click
- ✅ Error handling in message sending

### Conversation Sidebar
- ✅ New conversation button click
- ✅ Conversation item tap (to load)
- ✅ Delete conversation button click
- ✅ Delete confirmation dialog interactions

### Message Bubble
- ✅ Copy to clipboard button click
- ✅ Regenerate button click
- ✅ Copy operation success/failure

### Settings Panel
- ✅ Settings button click (open/close)
- ✅ Close settings button click
- ✅ Temperature slider changes
- ✅ Max tokens slider changes
- ✅ Max tokens text field changes
- ✅ Clear all conversations button click
- ✅ Clear all confirmation dialog interactions

### Home Screen
- ✅ Settings toggle (FAB button)
- ✅ Settings panel close

## Log Format

Each log entry is a JSON object with:
```json
{
  "sessionId": "debug-session-1234567890",
  "runId": "run-1234567890",
  "hypothesisId": "UI",
  "location": "chat_view.dart:46",
  "message": "User Interaction: send_message_clicked",
  "category": "user_interaction",
  "data": {
    "promptLength": 50,
    "isEmpty": false,
    "isLoading": false
  },
  "timestamp": 1234567890123
}
```

## Usage Examples

### Logging a User Interaction
```dart
DebugLogger.logUserInteraction(
  location: 'chat_view.dart:46',
  action: 'send_message_clicked',
  data: {'promptLength': prompt.length},
);
```

### Logging an Error
```dart
DebugLogger.logError(
  location: 'chat_view.dart:114',
  error: 'Failed to send message',
  originalError: e,
  context: {'conversationId': conversationId},
);
```

### Logging a State Change
```dart
DebugLogger.logStateChange(
  location: 'home_screen.dart:29',
  stateName: 'showSettings',
  oldValue: false,
  newValue: true,
);
```

### Logging a Dialog Interaction
```dart
DebugLogger.logDialog(
  location: 'conversation_sidebar.dart:177',
  action: 'delete_dialog_closed',
  dialogType: 'delete_conversation',
  result: confirmed,
);
```

## Finding Bugs

### Before (What Was Missing)
- ❌ User clicks weren't logged
- ❌ Dialog interactions weren't tracked
- ❌ Settings changes weren't monitored
- ❌ Error context was limited
- ❌ No visibility into blocked actions

### After (What's Now Tracked)
- ✅ Every button click is logged with context
- ✅ All dialog interactions are tracked
- ✅ Settings changes are monitored
- ✅ Errors include full context
- ✅ Blocked actions are logged with reasons

## Debugging Workflow

1. **Reproduce the bug** - All interactions are now logged
2. **Check the log file** - `.cursor/debug.log`
3. **Search for the action** - Find the user interaction that triggered the bug
4. **Trace the flow** - Follow the log entries to see what happened
5. **Identify the issue** - Look for errors, unexpected state changes, or missing operations

## Performance

The logging system is designed to be efficient:
- **Append-only writes** - No file reading, prevents exponential growth
- **Silent failures** - Logging errors don't break the app
- **Structured data** - Easy to parse and analyze

## Future Enhancements

Potential additions:
- Log filtering by category
- Log rotation (auto-cleanup old logs)
- Remote logging capability
- Performance profiling integration
- Visual log viewer

## Maintenance

When adding new features:
1. **Instrument all user interactions** - Every button, tap, input
2. **Log errors with context** - Include relevant state/data
3. **Track state changes** - Especially UI visibility toggles
4. **Monitor dialogs** - Track all dialog interactions

This comprehensive logging makes it possible to debug issues that were previously invisible!


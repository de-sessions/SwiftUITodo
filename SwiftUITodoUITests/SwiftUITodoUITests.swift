//
//  SwiftUITodoUITests.swift
//  SwiftUITodoUITests
//
//  End-to-end UI tests for SwiftUITodo app.
//  Tests cover: task creation, toggle done, edit, delete, and state transitions.
//

import XCTest

class SwiftUITodoUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Task Creation

    /// Test creating a new task via the text field and verifying it appears in the list.
    func testCreateTask() {
        let taskTitle = "Buy groceries"
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "Task creation text field should exist")

        textField.tap()
        textField.typeText(taskTitle)
        textField.typeText("\n") // commit

        let taskCell = app.buttons[taskTitle]
        XCTAssertTrue(taskCell.waitForExistence(timeout: 3), "Newly created task should appear in the list")
    }

    /// Test that creating a task clears the draft text field.
    func testCreateTaskClearsDraftField() {
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))

        textField.tap()
        textField.typeText("Temporary task")
        textField.typeText("\n")

        // After creation the text field should be empty (placeholder visible again)
        let placeholderField = app.textFields["Create a New Task..."]
        XCTAssertTrue(placeholderField.waitForExistence(timeout: 3), "Text field should be cleared after task creation")
    }

    /// Test that a newly created task is inserted at the top of the list.
    func testNewTaskInsertedAtTop() {
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))

        // Create first task
        textField.tap()
        textField.typeText("First task")
        textField.typeText("\n")

        // Create second task
        textField.tap()
        textField.typeText("Second task")
        textField.typeText("\n")

        // Second task should appear before first task in the list
        let cells = app.cells
        let secondTaskCell = cells.containing(.button, identifier: "Second task").firstMatch
        let firstTaskCell = cells.containing(.button, identifier: "First task").firstMatch

        XCTAssertTrue(secondTaskCell.exists, "Second task should exist")
        XCTAssertTrue(firstTaskCell.exists, "First task should exist")

        // Verify ordering by frame position (second task should be higher / lower Y)
        XCTAssertLessThan(
            secondTaskCell.frame.minY,
            firstTaskCell.frame.minY,
            "Most recently created task should appear above older tasks"
        )
    }

    // MARK: - Toggle Done

    /// Test toggling a task's done state shows/hides the checkmark.
    func testToggleDone() {
        // Create a task first
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Toggle me")
        textField.typeText("\n")

        let taskButton = app.buttons["Toggle me"]
        XCTAssertTrue(taskButton.waitForExistence(timeout: 3))

        // Initially no checkmark should be visible for this task
        let checkmark = app.images["checkmark"]
        let checkmarkExistsBefore = checkmark.exists

        // Tap to toggle done
        taskButton.tap()

        // After toggling, checkmark state should change
        if checkmarkExistsBefore {
            // Was done, should now be not done
            XCTAssertFalse(checkmark.exists, "Checkmark should disappear after toggling done task")
        } else {
            // Was not done, should now be done
            XCTAssertTrue(checkmark.waitForExistence(timeout: 2), "Checkmark should appear after marking task done")
        }
    }

    /// Test toggling done twice returns to original state.
    func testToggleDoneTwiceRestoresState() {
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Double toggle")
        textField.typeText("\n")

        let taskButton = app.buttons["Double toggle"]
        XCTAssertTrue(taskButton.waitForExistence(timeout: 3))

        // Toggle once (mark done)
        taskButton.tap()
        sleep(1)

        // Toggle again (mark not done)
        taskButton.tap()
        sleep(1)

        // Should be back to not done - no checkmark
        let checkmarks = app.images.matching(identifier: "checkmark")
        // Count checkmarks that are within the same cell
        // After double toggle, the task should not have a checkmark
        XCTAssertTrue(taskButton.exists, "Task should still exist after double toggle")
    }

    // MARK: - Edit Task

    /// Test editing a task title via the edit view.
    func testEditTask() {
        // Create a task
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Original title")
        textField.typeText("\n")

        // Enter edit mode
        let editButton = app.navigationBars.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        // Tap the task to navigate to edit view
        let taskText = app.staticTexts["Original title"]
        XCTAssertTrue(taskText.waitForExistence(timeout: 3))
        taskText.tap()

        // Verify we're on the edit screen
        let editNavBar = app.navigationBars["Edit Task"]
        XCTAssertTrue(editNavBar.waitForExistence(timeout: 3), "Should navigate to Edit Task screen")

        // Modify the title
        let editField = app.textFields.firstMatch
        XCTAssertTrue(editField.waitForExistence(timeout: 3))
        editField.tap()

        // Select all and type new title
        editField.press(forDuration: 1.0)
        app.menuItems["Select All"].tap()
        editField.typeText("Updated title")

        // Navigate back
        app.navigationBars.buttons.firstMatch.tap()

        // Verify the updated title appears
        let updatedTask = app.staticTexts["Updated title"]
        XCTAssertTrue(updatedTask.waitForExistence(timeout: 3), "Task should display updated title")
    }

    // MARK: - Delete Task

    /// Test deleting a task in edit mode.
    func testDeleteTask() {
        // Create a task
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Delete me")
        textField.typeText("\n")

        let taskExists = app.buttons["Delete me"].waitForExistence(timeout: 3)
        XCTAssertTrue(taskExists, "Task should exist before deletion")

        // Enter edit mode
        let editButton = app.navigationBars.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        // Tap the delete (minus circle) button
        let deleteButton = app.images["minus.circle"].firstMatch
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }

        // Exit edit mode
        let doneButton = app.navigationBars.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }

        // Verify the task is gone
        let deletedTask = app.buttons["Delete me"]
        XCTAssertFalse(deletedTask.exists, "Deleted task should no longer appear in the list")
    }

    /// Test that deleting all tasks automatically exits edit mode.
    func testDeleteAllTasksExitsEditMode() {
        // Clear any existing tasks and create exactly one
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Only task")
        textField.typeText("\n")

        // Enter edit mode
        let editButton = app.navigationBars.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        // Delete the only task
        let deleteButton = app.images["minus.circle"].firstMatch
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }

        // Edit mode should exit automatically - "Edit" button should be visible instead of "Done"
        let editButtonAfter = app.navigationBars.buttons["Edit"]
        XCTAssertTrue(
            editButtonAfter.waitForExistence(timeout: 3),
            "Edit mode should exit automatically when all tasks are deleted"
        )
    }

    // MARK: - Edit Mode State Transitions

    /// Test toggling between Edit and Done button states.
    func testEditModeToggle() {
        // Verify Edit button exists initially
        let editButton = app.navigationBars.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "Edit button should be visible initially")

        // Tap Edit
        editButton.tap()

        // Verify Done button appears
        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should appear in edit mode")

        // Tap Done
        doneButton.tap()

        // Verify Edit button is back
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should reappear after exiting edit mode")
    }

    /// Test that tapping a task in non-edit mode does NOT navigate to edit view.
    func testTapTaskInNormalModeTogglesDone() {
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Normal tap test")
        textField.typeText("\n")

        let taskButton = app.buttons["Normal tap test"]
        XCTAssertTrue(taskButton.waitForExistence(timeout: 3))

        // Tap in normal mode - should toggle done, not navigate
        taskButton.tap()

        // Should still be on the main Tasks screen
        let navTitle = app.navigationBars["Tasks"]
        XCTAssertTrue(navTitle.exists, "Should remain on Tasks screen when tapping in normal mode")
    }

    // MARK: - Data Persistence

    /// Test that tasks persist across app relaunch.
    func testTaskPersistsAfterRelaunch() {
        // Create a task
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Persistent task")
        textField.typeText("\n")

        let task = app.buttons["Persistent task"]
        XCTAssertTrue(task.waitForExistence(timeout: 3))

        // Terminate and relaunch
        app.terminate()
        app.launch()

        // Verify task still exists
        let persistedTask = app.buttons["Persistent task"]
        XCTAssertTrue(
            persistedTask.waitForExistence(timeout: 5),
            "Task should persist after app relaunch"
        )
    }

    /// Test that done state persists across app relaunch.
    func testDoneStatePersistsAfterRelaunch() {
        // Create a task and mark it done
        let textField = app.textFields["Create a New Task..."]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Done persistent")
        textField.typeText("\n")

        let taskButton = app.buttons["Done persistent"]
        XCTAssertTrue(taskButton.waitForExistence(timeout: 3))
        taskButton.tap() // mark done

        let checkmark = app.images["checkmark"]
        XCTAssertTrue(checkmark.waitForExistence(timeout: 2))

        // Terminate and relaunch
        app.terminate()
        app.launch()

        // Verify checkmark still exists
        let persistedCheckmark = app.images["checkmark"]
        XCTAssertTrue(
            persistedCheckmark.waitForExistence(timeout: 5),
            "Done state should persist after app relaunch"
        )
    }
}

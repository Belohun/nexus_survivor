# Flame Engine Style Guide Rules

This project uses the [Flame Engine](https://flame-engine.org/) game framework for Flutter. Follow
these rules when writing or modifying code. 
The nexus survivor is a looter shooter with rouglike elements and tower defense with the main objective is to protect the nexus from waves of enemies.

## General

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart) as the
  baseline.
- Use `fvm` before every flutter and dart command.
- Run `fvm flutter analyze` and `fvm dart format .` before committing to ensure code conformance.

## Code Formatting

- Use `fvm dart format` for automatic formatting.
- Keep lines within the Dart formatter's default line length.

## Imports

- When an external symbol is defined in multiple libraries, prefer importing the smallest one.
  For example, use `package:meta/meta.dart` for annotations like `@protected`, or `dart:ui` for
  `Canvas`.
- **Never** import `package:flutter/cupertino.dart` or `package:flutter/material.dart`. Use
  `package:flutter/widgets.dart` instead when working with widgets.

## Exports & File Organization

- **One public class per file.** Name the file after that class (in `snake_case`). Multiple private
  classes in the same file are fine.
- Small public helper classes tightly coupled to the main class may share the file.
- Place the **main class at the top** of the file, right after imports. Typedefs, helper classes,
  and functions go below it.
- When a file defines multiple public symbols, export them explicitly:
  ```dart
  export 'src/effects/provider_interfaces.dart'
    show
      AnchorProvider,
      AngleProvider,
      PositionProvider,
      ScaleProvider,
      SizeProvider;
  ```

## Class Structure

- Put **all constructors at the top** of the class.
- Make as much of the class API **private** as possible. Do not expose members "just in case."
- Document **all public members** with dartdocs (`///`).
- Treat exposed `List<X>` or `Vector2` properties as **read-only** unless documentation explicitly
  says otherwise.
- Use **regions** to organize large classes:
  ```dart
  //#region Region description
  ...
  //#endregion
  ```
- For private members exposed via getter/setter, group private fields near the top and place the
  getter/setter pair below:
  ```dart
  class MyClass {
    MyClass();

    int _variable;

    /// Docs for both the getter and the setter.
    int get variable => _variable;
    set variable(int value) {
      assert(value >= 0, 'variable must be non-negative: $value');
      _variable = value;
    }
  }
  ```

## Assertions & Error Handling

- Use `assert` with a **clear error message** for developer-controlled pre/post-conditions.
  Include the offending value in the message:
  ```dart
  assert(0 <= opacity && opacity <= 1, 'The opacity value must be from 0 to 1: $opacity');
  ```
- Place asserts **as early as possible** (constructors/setters, not render methods).
- When adding an assert, also add a **test** that verifies the assert triggers and the message is
  correct.
- Use `assert` **without** an error message only for internal invariants that should never be
  reachable by external callers. These act as "mini-tests" guarding against regression.
- Use explicit **if-check + exception** for conditions that may be outside the developer's control
  (e.g., environment or user input that could fail in production after thorough testing).

## Documentation

### Dartdocs (`///`)

- Use dartdocs to explain the **meaning/purpose** of a class, method, or variable.
- **Class docs** should start with the class name in brackets:
  ```dart
  /// [MyClass] is ...
  /// [MyClass] serves as ...
  ```
- **Method docs** should start with a verb in present simple tense (implicit subject is the method
  name). Add a paragraph break after the first sentence. Mention pre/post-conditions:
  ```dart
  /// Adds a new [child] into the container, and becomes the owner of that
  /// child.
  ///
  /// The child will be disposed of when this container is destroyed.
  /// It is an error to try to add a child that already belongs to another
  /// container.
  void addChild(T child) { ... }
  ```
- **Constructor docs**: Use "Creates …" / "Constructs …" style, or describe the object shape.
  May be omitted if it's the main constructor and all parameters are obvious.
- **Do not** use macros to copy class docs into constructor docs.
- Avoid stating only the obvious.

### Regular Comments (`//`)

- Use regular comments to explain **how** something works (implementation details).

### Markdown Documentation

- Maximum line length of **100 characters**.
- Define external links at the **bottom** of the document.
- Separate headers from preceding content with **2 blank lines**.
- Start lists at the beginning of the line; indent sublists with **2 spaces**.


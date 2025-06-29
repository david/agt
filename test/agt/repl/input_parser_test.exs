defmodule Agt.REPL.InputParserTest do
  use ExUnit.Case, async: false

  alias Agt.REPL.InputParser

  # --- Single-Line Prompt Behavior ---

  test "single-line: basic input" do
    assert InputParser.parse_first_line("Hello world\n") == {:single_line, "Hello world"}
  end

  test "single-line: whitespace trimming" do
    assert InputParser.parse_first_line("  test  \n") == {:single_line, "test"}
  end

  test "single-line: empty line" do
    assert InputParser.parse_first_line("\n") == :ignore
  end

  test "single-line: whitespace only" do
    assert InputParser.parse_first_line("   \n") == :ignore
  end

  test "single-line: literal |" do
    assert InputParser.parse_first_line("Hello|World\n") == {:single_line, "Hello|World"}
  end

  test "single-line: literal ." do
    assert InputParser.parse_first_line(".hello\n") == {:single_line, ".hello"}
  end

  # --- Multi-Line Prompt Behavior ---

  test "multi-line: initiation (prefix |)" do
    assert InputParser.parse_first_line("|First line\n") == {:multi_line_start, "First line"}

    assert InputParser.parse_continuation_line("Second line\n", ["First line"]) ==
             {:continue, ["Second line", "First line"]}

    assert InputParser.parse_continuation_line(".\n", ["Second line", "First line"]) ==
             {:finished, "First line\nSecond line"}
  end

  test "multi-line: initiation (suffix |)" do
    assert InputParser.parse_first_line("First line|\n") == {:multi_line_start, "First line"}

    assert InputParser.parse_continuation_line("Second line\n", ["First line"]) ==
             {:continue, ["Second line", "First line"]}

    assert InputParser.parse_continuation_line(".\n", ["Second line", "First line"]) ==
             {:finished, "First line\nSecond line"}
  end

  test "multi-line: preserving empty lines & indentation" do
    initial_state = InputParser.parse_first_line("|Line 1\n")
    assert initial_state == {:multi_line_start, "Line 1"}

    {:continue, lines1} =
      InputParser.parse_continuation_line("Line 2\n", [elem(initial_state, 1)])

    {:continue, lines2} = InputParser.parse_continuation_line("\n", lines1)
    {:continue, lines3} = InputParser.parse_continuation_line("    Line 4\n", lines2)

    assert InputParser.parse_continuation_line(".\n", lines3) ==
             {:finished, "Line 1\nLine 2\n\n    Line 4"}
  end

  test "multi-line: only whitespace/empty lines (ignored)" do
    initial_state = InputParser.parse_first_line("|   \n")
    assert initial_state == {:multi_line_start, "   "}
    {:continue, lines1} = InputParser.parse_continuation_line("\n", [elem(initial_state, 1)])
    assert InputParser.parse_continuation_line(".\n", lines1) == {:finished, :ignore}
  end

  test "multi-line: literal | on subsequent lines" do
    initial_state = InputParser.parse_first_line("|Hello\n")
    {:continue, lines} = InputParser.parse_continuation_line("World|\n", [elem(initial_state, 1)])
    assert InputParser.parse_continuation_line(".\n", lines) == {:finished, "Hello\nWorld|"}
  end

  test "multi-line: literal . within a line" do
    initial_state = InputParser.parse_first_line("|This is a . test\n")

    {:continue, lines} =
      InputParser.parse_continuation_line("Another line with..dots\n", [elem(initial_state, 1)])

    assert InputParser.parse_continuation_line(".\n", lines) ==
             {:finished, "This is a . test\nAnother line with..dots"}
  end

  test "multi-line: . (period with trailing spaces) as non-terminator" do
    initial_state = InputParser.parse_first_line("|Hello\n")
    {:continue, lines1} = InputParser.parse_continuation_line(". \n", [elem(initial_state, 1)])
    {:continue, lines2} = InputParser.parse_continuation_line("World\n", lines1)
    assert InputParser.parse_continuation_line(".\n", lines2) == {:finished, "Hello\n. \nWorld"}
  end

  test "multi-line: empty first line but multi-line trigger" do
    initial_state = InputParser.parse_first_line("|\n")
    assert initial_state == {:multi_line_start, ""}

    {:continue, lines} =
      InputParser.parse_continuation_line("Actual content\n", [elem(initial_state, 1)])

    assert InputParser.parse_continuation_line(".\n", lines) == {:finished, "Actual content"}
  end

  test "multi-line: only trigger and termination" do
    initial_state = InputParser.parse_first_line("|\n")
    assert initial_state == {:multi_line_start, ""}

    assert InputParser.parse_continuation_line(".\n", [elem(initial_state, 1)]) ==
             {:finished, :ignore}
  end

  test "multi-line: single line with multi-line trigger" do
    initial_state = InputParser.parse_first_line("|Single line\n")
    assert initial_state == {:multi_line_start, "Single line"}

    assert InputParser.parse_continuation_line(".\n", [elem(initial_state, 1)]) ==
             {:finished, "Single line"}
  end
end

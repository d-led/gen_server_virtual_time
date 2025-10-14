#!/bin/bash
# Script to add a new example placeholder to reports/index.html
#
# Usage: ./scripts/new-example-docs-placeholder.sh <type> <title> <description> <filename>
#
# Arguments:
#   type        - Badge type: 'flowchart' or 'sequence'
#   title       - Example title (e.g., "My New Example")
#   description - Brief description of the example
#   filename    - Output HTML filename (e.g., "my_example.html")
#
# Example:
#   ./scripts/new-example-docs-placeholder.sh flowchart "Custom Pipeline" "A custom message processing pipeline" custom_pipeline.html

set -e

# Check arguments
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <type> <title> <description> <filename>"
  echo ""
  echo "Arguments:"
  echo "  type        - Badge type: 'flowchart' or 'sequence'"
  echo "  title       - Example title (e.g., 'My New Example')"
  echo "  description - Brief description"
  echo "  filename    - Output HTML filename (e.g., 'my_example.html')"
  echo ""
  echo "Example:"
  echo "  $0 flowchart \"Custom Pipeline\" \"A custom processing pipeline\" custom_pipeline.html"
  exit 1
fi

TYPE="$1"
TITLE="$2"
DESCRIPTION="$3"
FILENAME="$4"

# Validate type
if [ "$TYPE" != "flowchart" ] && [ "$TYPE" != "sequence" ]; then
  echo "Error: type must be 'flowchart' or 'sequence'"
  exit 1
fi

# Capitalize type for badge
TYPE_DISPLAY=$(echo "${TYPE:0:1}" | tr '[:lower:]' '[:upper:]')${TYPE:1}

# File to modify
REPORTS_INDEX="generated/examples/reports/index.html"

if [ ! -f "$REPORTS_INDEX" ]; then
  echo "Error: $REPORTS_INDEX not found"
  exit 1
fi

# Create a temporary file with the new card
TEMP_CARD=$(mktemp)
cat > "$TEMP_CARD" << EOF

      <div class="report-card">
        <span class="badge $TYPE">$TYPE_DISPLAY</span>
        <h3>$TITLE</h3>
        <p>$DESCRIPTION</p>
        <a href="$FILENAME" target="_blank">View Report →</a>
      </div>
EOF

# Create a backup
cp "$REPORTS_INDEX" "$REPORTS_INDEX.bak"

# Determine the marker to insert before based on type
if [ "$TYPE" == "flowchart" ]; then
  MARKER='    <h2>🎬 Mermaid Sequence Diagrams</h2>'
else
  MARKER='    <h2>🍴 Dining Philosophers Examples</h2>'
fi

# Use sed to insert before the marker section
# First, find the line number of the marker
LINE_NUM=$(grep -n "$MARKER" "$REPORTS_INDEX.bak" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
  echo "Error: Could not find insertion point marker"
  rm "$TEMP_CARD"
  exit 1
fi

# We want to insert before the closing </div></div> that precedes the marker
# Go back from LINE_NUM to find the section closing
INSERT_LINE=$((LINE_NUM - 3))

# Split the file and insert
head -n "$INSERT_LINE" "$REPORTS_INDEX.bak" > "$REPORTS_INDEX"
cat "$TEMP_CARD" >> "$REPORTS_INDEX"
tail -n +"$((INSERT_LINE + 1))" "$REPORTS_INDEX.bak" >> "$REPORTS_INDEX"

# Cleanup
rm "$TEMP_CARD"

echo "✅ Added new $TYPE example card to $REPORTS_INDEX"
echo ""
echo "Card details:"
echo "  Title: $TITLE"
echo "  Description: $DESCRIPTION"
echo "  Filename: $FILENAME"
echo "  Type: $TYPE"
echo ""
echo "Backup saved to: $REPORTS_INDEX.bak"
echo ""
echo "Next steps:"
echo "  1. Generate the actual HTML file: generated/examples/reports/$FILENAME"
echo "  2. Review the changes in $REPORTS_INDEX"
echo "  3. Remove backup if satisfied: rm $REPORTS_INDEX.bak"

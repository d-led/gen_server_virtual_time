#!/bin/bash
# Script to add a new generator placeholder to generators.html
#
# Usage: ./scripts/new-generator-docs-placeholder.sh <name> <language> <framework_url> <examples...>
#
# Arguments:
#   name          - Generator name (e.g., "Akka")
#   language      - Language: 'cpp', 'java', 'pony', 'go', 'rust', 'erlang', etc.
#   framework_url - URL to framework homepage (e.g., "https://akka.io/")
#   examples...   - Space-separated list of example names (e.g., "burst pipeline pubsub")
#
# Example:
#   ./scripts/new-generator-docs-placeholder.sh "Akka" java "https://akka.io/" burst pipeline pubsub

set -e

# Check arguments
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <name> <language> <framework_url> <examples...>"
  echo ""
  echo "Arguments:"
  echo "  name          - Generator name (e.g., 'Akka')"
  echo "  language      - Language badge: 'cpp', 'java', 'pony', 'go', 'rust', 'erlang', etc."
  echo "  framework_url - URL to framework homepage (e.g., 'https://akka.io/')"
  echo "  examples...   - Space-separated list of example names (e.g., 'burst pipeline pubsub')"
  echo ""
  echo "Example:"
  echo "  $0 \"Akka\" java \"https://akka.io/\" burst pipeline pubsub"
  exit 1
fi

NAME="$1"
LANGUAGE="$2"
FRAMEWORK_URL="$3"
shift 3
EXAMPLES=("$@")

# Validate language and set badge class
case "$LANGUAGE" in
  cpp|c++)
    BADGE_CLASS="cpp"
    LANGUAGE_DISPLAY="C++"
    ;;
  java)
    BADGE_CLASS="java"
    LANGUAGE_DISPLAY="Java"
    ;;
  pony)
    BADGE_CLASS="pony"
    LANGUAGE_DISPLAY="Pony"
    ;;
  go|golang)
    BADGE_CLASS="go"
    LANGUAGE_DISPLAY="Go"
    ;;
  rust)
    BADGE_CLASS="rust"
    LANGUAGE_DISPLAY="Rust"
    ;;
  erlang)
    BADGE_CLASS="erlang"
    LANGUAGE_DISPLAY="Erlang"
    ;;
  elixir)
    BADGE_CLASS="elixir"
    LANGUAGE_DISPLAY="Elixir"
    ;;
  *)
    BADGE_CLASS="$LANGUAGE"
    LANGUAGE_DISPLAY="$LANGUAGE"
    ;;
esac

# Generate example links
TEMP_EXAMPLES=$(mktemp)
GENERATOR_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
for example in "${EXAMPLES[@]}"; do
  echo "              <a href=\"https://github.com/d-led/gen_server_virtual_time/tree/main/examples/${GENERATOR_LOWER}_${example}\" class=\"example-link\" target=\"_blank\">$example</a>" >> "$TEMP_EXAMPLES"
done

# File to modify
GENERATORS_HTML="generated/examples/generators.html"

if [ ! -f "$GENERATORS_HTML" ]; then
  echo "Error: $GENERATORS_HTML not found"
  rm "$TEMP_EXAMPLES"
  exit 1
fi

# Create the new table row in a temporary file
TEMP_ROW=$(mktemp)
cat > "$TEMP_ROW" << EOF
        
        <tr>
          <td>
            <div class="framework-name">$NAME</div>
            <a href="$FRAMEWORK_URL" class="framework-link" target="_blank">$NAME Framework →</a>
          </td>
          <td><span class="badge $BADGE_CLASS">$LANGUAGE_DISPLAY</span></td>
          <td>
            <div class="output-features">
              • TODO: Add feature 1<br>
              • TODO: Add feature 2<br>
              • TODO: Add feature 3<br>
              • TODO: Add feature 4
            </div>
          </td>
          <td>
            <div class="examples-list">
EOF

cat "$TEMP_EXAMPLES" >> "$TEMP_ROW"

cat >> "$TEMP_ROW" << EOF
            </div>
          </td>
        </tr>
EOF

# Create a backup
cp "$GENERATORS_HTML" "$GENERATORS_HTML.bak"

# Find the closing </tbody> tag and insert before it
LINE_NUM=$(grep -n "^      </tbody>$" "$GENERATORS_HTML.bak" | head -1 | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
  echo "Error: Could not find </tbody> tag"
  rm "$TEMP_ROW" "$TEMP_EXAMPLES"
  exit 1
fi

# Insert before the </tbody> line
head -n "$((LINE_NUM - 1))" "$GENERATORS_HTML.bak" > "$GENERATORS_HTML"
cat "$TEMP_ROW" >> "$GENERATORS_HTML"
tail -n +"$LINE_NUM" "$GENERATORS_HTML.bak" >> "$GENERATORS_HTML"

# Cleanup
rm "$TEMP_ROW" "$TEMP_EXAMPLES"

echo "✅ Added new generator row to $GENERATORS_HTML"
echo ""
echo "Generator details:"
echo "  Name: $NAME"
echo "  Language: $LANGUAGE_DISPLAY"
echo "  Framework URL: $FRAMEWORK_URL"
echo "  Examples: ${EXAMPLES[*]}"
echo ""
echo "Backup saved to: $GENERATORS_HTML.bak"
echo ""
echo "⚠️  IMPORTANT: Please manually edit the generator features in $GENERATORS_HTML"
echo "   Search for 'TODO: Add feature' and replace with actual features."
echo ""
echo "Next steps:"
echo "  1. Edit $GENERATORS_HTML and update the features section"
echo "  2. Review the changes"
echo "  3. Remove backup if satisfied: rm $GENERATORS_HTML.bak"
echo ""
if [ "$BADGE_CLASS" == "$LANGUAGE" ] && [ "$BADGE_CLASS" != "cpp" ] && [ "$BADGE_CLASS" != "java" ] && [ "$BADGE_CLASS" != "pony" ] && [ "$BADGE_CLASS" != "go" ]; then
  echo "⚠️  Don't forget to add the CSS for the language badge!"
  echo "Add to the <style> section in $GENERATORS_HTML:"
  echo ""
  echo "    .badge.$BADGE_CLASS {"
  echo "      background: #CHOOSE_COLOR;"
  echo "      color: #CHOOSE_COLOR;"
  echo "    }"
fi

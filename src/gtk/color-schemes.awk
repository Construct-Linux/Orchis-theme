# awk -f color-schemes.awk LIGHT.css DARK.css
#
# Prints one stylesheet that styles as LIGHT.css under a light (or no) colour-scheme
# preference and as DARK.css under a dark one, carrying a rule the two share once instead
# of twice: libadwaita apps read a single ~/.config/gtk-4.0/gtk.css, and GTK 4 never loads
# gtk-dark.css there.
#
# Both files come from the same sources in the same order, so most rules match. Each dark
# rule is paired with the next identical light rule; between two pairs, the unpaired light
# rules go under @media (prefers-color-scheme: light) and the unpaired dark ones right after
# under @media (prefers-color-scheme: dark). Either preference then sees exactly its own
# file's rules in its own file's order, so the cascade cannot differ from that file's. GTK
# matches `light` for every preference but dark, including none.
# Comments are dropped; rules and statements (@define-color) are compared as text.

function store(f) {
  text[f, ++count[f]] = buf
  buf = ""
}

function block(scheme, f, from, to,    i) {
  if (from > to) return
  print "@media (prefers-color-scheme: " scheme ") {"
  for (i = from; i <= to; i++) print text[f, i]
  print "}"
  print ""
}

FNR == 1 { file++; buf = ""; incomment = 0; inrule = 0 }

incomment {
  if (index($0, "*/")) incomment = 0
  next
}

inrule {
  buf = buf "\n" $0
  if ($0 == "}") { inrule = 0; store(file) }
  next
}

/^\/\*/ {
  if (!index($0, "*/")) incomment = 1
  next
}

/^[ \t]*$/ { next }

{
  buf = $0
  if (index($0, "{") == 0 && $0 ~ /;[ \t]*$/) store(file)
  else inrule = 1
}

END {
  if (incomment || inrule) { print "color-schemes.awk: unterminated rule or comment" > "/dev/stderr"; exit 1 }

  # A light rule more than 64 rules ahead is not looked for: the dark rule then stays
  # unpaired, which costs size, never correctness.
  l = 1
  d = 1
  for (j = 1; j <= count[2]; j++) {
    for (i = l; i <= count[1] && i < l + 64; i++) {
      if (text[1, i] != text[2, j]) continue
      block("light", 1, l, i - 1)
      block("dark", 2, d, j - 1)
      print text[1, i]
      print ""
      l = i + 1
      d = j + 1
      break
    }
  }
  block("light", 1, l, count[1])
  block("dark", 2, d, count[2])
}

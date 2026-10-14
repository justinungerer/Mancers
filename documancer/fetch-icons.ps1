param([string] $Src, [string] $Dest)
$ErrorActionPreference = 'Stop'
# Existing icon name (kept, so code references stay valid) -> Phosphor regular icon name.
# "a|b" tries a first, then b.
$map = [ordered]@{
  'accessibility' = 'person-arms-spread|person'; 'align-center' = 'text-align-center'; 'align-justify' = 'text-align-justify'
  'align-left' = 'text-align-left'; 'align-right' = 'text-align-right'; 'app-window' = 'app-window'; 'arrow-left-right' = 'arrows-left-right'
  'arrow-up-down' = 'arrows-down-up'; 'arrow-up-right' = 'arrow-up-right'; 'badge-check' = 'seal-check'; 'bandage' = 'bandaids'
  'bell' = 'bell'; 'blend' = 'intersect'; 'bold' = 'text-b'; 'book-open' = 'book-open'; 'bookmark-plus' = 'bookmarks'
  'bookmark' = 'bookmark-simple'; 'braces' = 'brackets-curly'; 'brush-cleaning' = 'broom'; 'brush' = 'paint-brush'; 'camera' = 'camera'
  'check-circle-2' = 'check-circle'; 'check' = 'check'; 'chevron-down' = 'caret-down'; 'chevron-left' = 'caret-left'
  'chevron-right' = 'caret-right'; 'chevron-up' = 'caret-up'; 'chevrons-left' = 'caret-double-left'; 'chevrons-right' = 'caret-double-right'
  'circle-check' = 'check-circle'; 'circle-dashed' = 'circle-dashed'; 'circle-dot' = 'record'; 'circle-help' = 'question'
  'circle-x' = 'x-circle'; 'circle' = 'circle'; 'clipboard-paste' = 'clipboard-text'; 'clock-3' = 'clock-afternoon|clock'
  'clock' = 'clock'; 'cloud-upload' = 'cloud-arrow-up'; 'cloud' = 'cloud'; 'code-xml' = 'code'; 'columns-2' = 'columns'
  'columns-3' = 'kanban'; 'compass' = 'compass'; 'contrast' = 'circle-half'; 'copy-plus' = 'copy-simple'; 'copy' = 'copy'
  'crop' = 'crop'; 'droplet' = 'drop'; 'ellipsis-vertical' = 'dots-three-vertical'; 'ellipsis' = 'dots-three'; 'eraser' = 'eraser'
  'external-link' = 'arrow-square-out'; 'eye-off' = 'eye-slash'; 'eye' = 'eye'; 'file-check' = 'file-check|file-text'
  'file-code' = 'file-code'; 'file-down' = 'file-arrow-down'; 'file-input' = 'arrow-square-in'; 'file-lock-2' = 'file-lock'
  'file-minus' = 'file-minus'; 'file-output' = 'export'; 'file-pen-line' = 'note-pencil'; 'file-plus-2' = 'file-plus'
  'file-plus' = 'file-plus'; 'file-scan' = 'file-dashed'; 'file-search' = 'file-magnifying-glass'; 'file-spreadsheet' = 'file-xls'
  'file-symlink' = 'file-arrow-up'; 'file-text' = 'file-text'; 'file-x' = 'file-x'; 'files' = 'files'; 'film' = 'film-strip'
  'filter' = 'funnel'; 'flip-horizontal-2' = 'flip-horizontal'; 'flip-vertical-2' = 'flip-vertical'; 'folder-open' = 'folder-open'
  'folder-plus' = 'folder-plus'; 'folder' = 'folder'; 'gauge' = 'gauge'; 'git-compare' = 'git-diff'; 'globe' = 'globe'
  'grid-3x3' = 'grid-nine'; 'hand' = 'hand'; 'hash' = 'hash'; 'heading' = 'text-h'; 'highlighter' = 'highlighter|highlighter-circle'
  'house' = 'house'; 'image-plus' = 'image-square'; 'image' = 'image'; 'info' = 'info'; 'italic' = 'text-italic'
  'languages' = 'translate'; 'lasso' = 'lasso'; 'layers' = 'stack'; 'layout-grid' = 'squares-four'; 'link-2' = 'link-simple'
  'link' = 'link'; 'list-checks' = 'list-checks'; 'list-ordered' = 'list-numbers'; 'list' = 'list'; 'lock-open' = 'lock-open'
  'lock' = 'lock'; 'maximize-2' = 'arrows-out'; 'maximize' = 'corners-out'; 'message-circle-reply' = 'chat-circle'
  'message-square-plus' = 'chat-centered-text'; 'message-square-quote' = 'quotes'; 'message-square-text' = 'chat-text'
  'message-square' = 'chat'; 'messages-square' = 'chats'; 'mic' = 'microphone'; 'minimize' = 'corners-in'; 'minus' = 'minus'
  'moon' = 'moon'; 'mouse-pointer-2' = 'cursor'; 'move-right' = 'arrow-right'; 'move' = 'arrows-out-cardinal'
  'navigation' = 'navigation-arrow'; 'paint-bucket' = 'paint-bucket'; 'palette' = 'palette'; 'panel-left' = 'sidebar'
  'panel-right' = 'sidebar-simple'; 'panels-top-left' = 'layout'; 'paperclip' = 'paperclip'; 'pen-line' = 'pen'; 'pen-tool' = 'pen-nib'
  'pencil' = 'pencil-simple'; 'pentagon' = 'polygon'; 'pin' = 'push-pin'; 'pipette' = 'eyedropper'; 'plus' = 'plus'
  'presentation' = 'presentation'; 'printer' = 'printer'; 'rectangle-horizontal' = 'rectangle'; 'redo-2' = 'arrow-clockwise'
  'replace' = 'swap'; 'reply' = 'arrow-bend-up-left'; 'rotate-ccw' = 'arrow-arc-left'; 'rotate-cw' = 'arrow-arc-right'; 'rows-3' = 'rows'
  'ruler' = 'ruler'; 'save' = 'floppy-disk'; 'scan-text' = 'scan'; 'scan' = 'frame-corners'; 'scissors' = 'scissors'
  'search' = 'magnifying-glass'; 'send' = 'paper-plane-right'; 'settings-2' = 'faders-horizontal'; 'settings' = 'gear-six'
  'share-2' = 'share-network'; 'shield-check' = 'shield-check'; 'signature' = 'signature'; 'sliders-horizontal' = 'sliders-horizontal'
  'sparkles' = 'sparkle'; 'spline' = 'bezier-curve'; 'square-dashed-mouse-pointer' = 'cursor-click'; 'square-dashed' = 'selection'
  'square-terminal' = 'terminal-window'; 'square' = 'square'; 'squares-subtract' = 'subtract-square'; 'stamp' = 'stamp'; 'star' = 'star'
  'sticky-note' = 'note'; 'strikethrough' = 'text-strikethrough'; 'sun' = 'sun'; 'swatch-book' = 'swatches'; 'tag' = 'tag'
  'text-cursor-input' = 'textbox'; 'text-select' = 'cursor-text'; 'thumbs-down' = 'thumbs-down'; 'thumbs-up' = 'thumbs-up'
  'trash-2' = 'trash'; 'trash' = 'trash-simple'; 'triangle-alert' = 'warning'; 'type' = 'text-t'; 'underline' = 'text-underline'
  'undo-2' = 'arrow-counter-clockwise'; 'user-round' = 'user-circle'; 'wand-sparkles' = 'magic-wand'; 'wrench' = 'wrench'; 'x' = 'x'
  'zoom-in' = 'magnifying-glass-plus'; 'zoom-out' = 'magnifying-glass-minus'
}
$wc = New-Object System.Net.WebClient
$wc.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
$wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$wc.Headers.Add('User-Agent', 'DocuMancer-dev')
New-Item -ItemType Directory -Force $Dest | Out-Null
$existing = Get-ChildItem $Src -Filter *.svg | ForEach-Object { $_.BaseName }
$unmapped = $existing | Where-Object { -not $map.Contains($_) }
if ($unmapped) { Write-Output "UNMAPPED: $($unmapped -join ', ')" }
$missing = @()
$used = [ordered]@{}
foreach ($k in $map.Keys) {
  $svg = $null
  foreach ($name in ($map[$k] -split '\|')) {
    try { $svg = $wc.DownloadString("https://raw.githubusercontent.com/phosphor-icons/core/main/assets/regular/$name.svg"); $used[$k] = $name; break }
    catch { }
  }
  if (-not $svg) { $missing += "$k -> $($map[$k])"; continue }
  [System.IO.File]::WriteAllText((Join-Path $Dest "$k.svg"), $svg.Trim() + "`n")
}
$used.GetEnumerator() | ForEach-Object { "$($_.Key)`t$($_.Value)" } | Set-Content (Join-Path $Dest 'map.tsv')
Write-Output "fetched: $($used.Count)  missing upstream: $($missing.Count)"
$missing | ForEach-Object { Write-Output "  $_" }

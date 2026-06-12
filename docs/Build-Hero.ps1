# Build-Hero.ps1 - generates docs/hero.svg (the repo hero / social banner).
# Theme: a hive (honeycomb) watching a privilege-escalation staircase climb
# from Guest -> Domain Admin, intercepted by the Hive watchdog at the top.
$ErrorActionPreference = 'Stop'
# Force '.' as the decimal separator so SVG coordinates are valid on any locale.
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
$W = 1280; $H = 640
$sb = [System.Text.StringBuilder]::new()

# Stylized geometric bee mascot, centered at (cx,cy), scaled and rotated.
function Get-Bee {
    param([double]$cx, [double]$cy, [double]$scale = 1, [double]$rot = 0)
    @"
<g transform='translate($cx,$cy) scale($scale) rotate($rot)'>
  <path d='M -5 -19 Q -11 -33 -16 -35' fill='none' stroke='#10231a' stroke-width='2' stroke-linecap='round'/>
  <circle cx='-16' cy='-35' r='2.4' fill='#10231a'/>
  <path d='M 5 -19 Q 9 -33 13 -33' fill='none' stroke='#10231a' stroke-width='2' stroke-linecap='round'/>
  <circle cx='13' cy='-33' r='2.4' fill='#10231a'/>
  <ellipse cx='-4' cy='-14' rx='13' ry='21' fill='#cdeeff' fill-opacity='0.6' stroke='#eaf7ff' stroke-opacity='0.5' transform='rotate(-26)'/>
  <ellipse cx='12' cy='-14' rx='12' ry='19' fill='#cdeeff' fill-opacity='0.5' stroke='#eaf7ff' stroke-opacity='0.4' transform='rotate(22)'/>
  <path d='M 0 25 L -4 33 L 4 33 Z' fill='#10231a'/>
  <ellipse cx='0' cy='4' rx='16' ry='21' fill='#ffc83d' stroke='#10231a' stroke-width='2'/>
  <g clip-path='url(#beebody)'>
    <rect x='-20' y='-9' width='40' height='6.5' fill='#10231a'/>
    <rect x='-20' y='3'  width='40' height='6.5' fill='#10231a'/>
    <rect x='-20' y='15' width='40' height='6.5' fill='#10231a'/>
  </g>
  <circle cx='0' cy='-17' r='8.5' fill='#10231a'/>
  <circle cx='-3' cy='-18' r='1.6' fill='#fff'/>
  <circle cx='3.5' cy='-18' r='1.6' fill='#fff'/>
</g>
"@
}

# ---- honeycomb backdrop (flat-top hexagons) ----
$R = 34
$dx = 1.5 * $R
$dy = [math]::Sqrt(3) * $R
$hex = [System.Text.StringBuilder]::new()
for ($col = -1; $col -lt [int]($W / $dx) + 2; $col++) {
    for ($row = -1; $row -lt [int]($H / $dy) + 2; $row++) {
        $cx = $col * $dx
        $cy = $row * $dy + $(if ($col % 2 -ne 0) { $dy / 2 } else { 0 })
        $pts = for ($i = 0; $i -lt 6; $i++) {
            $a = [math]::PI / 180 * (60 * $i)
            '{0:0.#},{1:0.#}' -f ($cx + $R * [math]::Cos($a)), ($cy + $R * [math]::Sin($a))
        }
        # honey-warm a cluster on the right (around the bee / watchdog)
        $near = ([math]::Abs($cx - 1140) -lt 160 -and [math]::Abs($cy - 200) -lt 175)
        $op = if ($near) { '0.20' } else { '0.05' }
        $sc = if ($near) { '#ffd23d' } else { '#37d39a' }
        $fl = if ($near) { 'fill="#ffb23d" fill-opacity="0.07"' } else { 'fill="none"' }
        [void]$hex.Append("<polygon points='$($pts -join ' ')' $fl stroke='$sc' stroke-width='1' opacity='$op'/>")
    }
}

# ---- escalation staircase nodes (Guest -> Domain Admin) ----
$nodes = @(
    @{ x = 900;  y = 520; label = 'Guest';        breach = $false },
    @{ x = 985;  y = 440; label = 'User';         breach = $false },
    @{ x = 1070; y = 360; label = 'Admin';        breach = $true  },
    @{ x = 1155; y = 280; label = 'Domain Admin'; breach = $true  }
)
$nodeSvg = [System.Text.StringBuilder]::new()
$nr = 30
foreach ($n in $nodes) {
    $pts = for ($i = 0; $i -lt 6; $i++) {
        $a = [math]::PI / 180 * (60 * $i + 30)
        '{0:0.#},{1:0.#}' -f ($n.x + $nr * [math]::Cos($a)), ($n.y + $nr * [math]::Sin($a))
    }
    $stroke = if ($n.breach) { '#ff7a3d' } else { '#37d39a' }
    $fill   = if ($n.breach) { '#1a130c' } else { '#0e2118' }
    $glow   = if ($n.breach) { " filter='url(#glow)'" } else { '' }
    [void]$nodeSvg.Append("<polygon points='$($pts -join ' ')' fill='$fill' stroke='$stroke' stroke-width='2.5'$glow/>")
    [void]$nodeSvg.Append("<text x='$($n.x - 44)' y='$($n.y + 4)' text-anchor='end' font-family='Segoe UI,sans-serif' font-size='15' fill='#8aa79a'>$($n.label)</text>")
}

$svg = @"
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $W $H' width='$W' height='$H' role='img' aria-label='Hive - Privilege Escalation Watchdog'>
<defs>
  <linearGradient id='bg' x1='0' y1='0' x2='1' y2='1'>
    <stop offset='0' stop-color='#08140e'/><stop offset='0.55' stop-color='#0a1c14'/><stop offset='1' stop-color='#06100b'/>
  </linearGradient>
  <radialGradient id='halo' cx='0.82' cy='0.3' r='0.5'>
    <stop offset='0' stop-color='#37d39a' stop-opacity='0.20'/><stop offset='1' stop-color='#37d39a' stop-opacity='0'/>
  </radialGradient>
  <filter id='glow' x='-60%' y='-60%' width='220%' height='220%'>
    <feGaussianBlur stdDeviation='6' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge>
  </filter>
  <clipPath id='beebody'><ellipse cx='0' cy='4' rx='16' ry='21'/></clipPath>
</defs>

<rect width='$W' height='$H' fill='url(#bg)'/>
<g>$($hex.ToString())</g>
<rect width='$W' height='$H' fill='url(#halo)'/>

<!-- escalation arrow climbing through the nodes -->
<path d='M 900 520 L 985 440 L 1070 360 L 1155 280' fill='none' stroke='#ff5d5d' stroke-width='3' stroke-dasharray='2 9' stroke-linecap='round' opacity='0.9' filter='url(#glow)'/>
<path d='M 1138 297 L 1155 280 L 1138 263' fill='none' stroke='#ff5d5d' stroke-width='3' stroke-linecap='round' stroke-linejoin='round' filter='url(#glow)'/>
$($nodeSvg.ToString())

<!-- watchdog hex with the Hive bee perched on top (intercepting) -->
<g filter='url(#glow)'>
  <polygon points='1195,150 1155,173 1115,150 1115,104 1155,81 1195,104' fill='#0e2118' stroke='#ffd23d' stroke-width='3'/>
</g>
$(Get-Bee -cx 1155 -cy 127 -scale 1.25)
<path d='M 1155 173 L 1155 250' stroke='#37d39a' stroke-width='2' stroke-dasharray='3 6' opacity='0.8'/>

<!-- small worker bee flying up the escalation path -->
$(Get-Bee -cx 1028 -cy 415 -scale 0.6 -rot -28)

<!-- wordmark + copy -->
<g transform='translate(96,0)'>
  <text x='0' y='150' font-family='Segoe UI,sans-serif' font-size='17' letter-spacing='3' fill='#37d39a'>MICROSOFT 365 COPILOT &#183; ENTERPRISE AGENTS</text>
  <polygon points='34,196 17,206 0,196 0,176 17,166 34,176' fill='none' stroke='#37d39a' stroke-width='3'/>
  <circle cx='17' cy='186' r='4' fill='#ffb23d'/>
  <text x='58' y='262' font-family='Segoe UI,Segoe UI Black,sans-serif' font-weight='800' font-size='120' fill='#e8f1ec' letter-spacing='2'>HIVE</text>
  <text x='4' y='330' font-family='Segoe UI,sans-serif' font-weight='700' font-size='40' fill='#ffb23d'>Privilege Escalation Watchdog</text>
  <text x='4' y='372' font-family='Segoe UI,sans-serif' font-size='20' fill='#8aa79a'>Multi-agent detection across hybrid identity. Catches escalation</text>
  <text x='4' y='400' font-family='Segoe UI,sans-serif' font-size='20' fill='#8aa79a'>precursors before full compromise &#183; MITRE ATT&amp;CK mapped.</text>
  <g font-family='Segoe UI,sans-serif' font-size='16' fill='#cfe0d8'>
    <rect x='4'   y='438' width='150' height='40' rx='20' fill='#0e2118' stroke='#1f3a2e'/><text x='79'  y='463' text-anchor='middle'>Role Change</text>
    <rect x='166' y='438' width='160' height='40' rx='20' fill='#0e2118' stroke='#1f3a2e'/><text x='246' y='463' text-anchor='middle'>Token Misuse</text>
    <rect x='338' y='438' width='196' height='40' rx='20' fill='#0e2118' stroke='#1f3a2e'/><text x='436' y='463' text-anchor='middle'>Lateral Movement</text>
  </g>
</g>
</svg>
"@

$out = Join-Path $PSScriptRoot 'hero.svg'
$svg | Out-File -FilePath $out -Encoding utf8
Write-Host "Wrote $out"

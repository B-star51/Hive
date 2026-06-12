# Build-Layout.ps1 - generates docs/project-layout.svg (a themed file-tree diagram).
$ErrorActionPreference = 'Stop'
# Force '.' as the decimal separator so SVG coordinates are valid on any locale.
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture

# depth, type (folder|file|root), name, description
$rows = @(
    @(0,'root',  'Hive/',                    'repo root'),
    @(1,'file',  'Invoke-Hive.ps1',          'CLI entry point + console report  (-Html dashboard)'),
    @(1,'file',  'SUBMISSION.md',             'Agents League submission write-up'),
    @(1,'file',  'README.md',                 'overview + Mermaid diagrams + hero'),
    @(1,'file',  'LICENSE',                   'MIT'),
    @(1,'folder','config/',                   ''),
    @(2,'file',  'settings.json',             'data-source toggles + correlation thresholds'),
    @(1,'folder','data/',                     'synthetic logs + attack playbooks'),
    @(2,'file',  'sample-ad-logs.json',       'Windows/AD events with a baked-in attack chain'),
    @(2,'file',  'playbooks/scenarios.md',    'what each scenario demonstrates'),
    @(1,'folder','src/',                      'the detection engine'),
    @(2,'folder','Core/',                     'EventModel, HiveCore, HiveReport, HiveHtmlReport'),
    @(2,'folder','Providers/',                'LocalJson (live) + AzureGraph/Sentinel (stubs)'),
    @(2,'folder','Agents/',                   'RoleChange . TokenMisuse . LateralMovement . Correlation . Response'),
    @(1,'folder','appPackage/',               'Microsoft 365 Copilot declarative agent'),
    @(2,'file',  'declarativeAgent.json',     'persona, conversation starters, safety instructions'),
    @(2,'file',  'ai-plugin.json',            'getHiveReport API action'),
    @(2,'file',  'hive-openapi.yaml',         'OpenAPI spec for the action'),
    @(2,'file',  'manifest.json',             'M365 app manifest'),
    @(2,'file',  'color.png / outline.png',   'app icons'),
    @(1,'folder','api/',                       'Azure Functions backend'),
    @(2,'folder','HiveReport/',                'GET /api/hive/report  (run.ps1 + function.json)'),
    @(1,'folder','tests/',                     'Pester suite - 14 tests, all green'),
    @(1,'folder','docs/',                      'hero art (hero.svg / hero.png) + generators')
)

$W = 1000
$top = 96
$lh = 30
$H = $top + $rows.Count * $lh + 34

$body = [System.Text.StringBuilder]::new()
for ($i = 0; $i -lt $rows.Count; $i++) {
    $depth = [int]$rows[$i][0]; $type = $rows[$i][1]; $name = $rows[$i][2]; $desc = $rows[$i][3]
    $y = $top + $i * $lh
    $x = 44 + $depth * 30

    if ($type -eq 'folder' -or $type -eq 'root') {
        # honey hexagon bullet
        $pts = for ($k = 0; $k -lt 6; $k++) {
            $a = [math]::PI / 180 * (60 * $k)
            '{0:0.#},{1:0.#}' -f ($x + 7 * [math]::Cos($a)), (($y - 5) + 7 * [math]::Sin($a))
        }
        [void]$body.Append("<polygon points='$($pts -join ' ')' fill='#ffb23d' fill-opacity='0.18' stroke='#e8c170' stroke-width='1.5'/>")
        $color = if ($type -eq 'root') { '#ffffff' } else { '#e8c170' }
        $weight = '700'
    } else {
        [void]$body.Append("<circle cx='$x' cy='$($y-5)' r='3' fill='#37d39a'/>")
        $color = '#e8f1ec'; $weight = '400'
    }
    [void]$body.Append("<text x='$($x+16)' y='$y' font-family='Consolas,Menlo,monospace' font-size='15' font-weight='$weight' fill='$color'>$name</text>")
    if ($desc) {
        [void]$body.Append("<text x='560' y='$y' font-family='Segoe UI,sans-serif' font-size='13.5' fill='#a8c0b5'>$desc</text>")
    }
}

$svg = @"
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 $W $H' width='$W' height='$H' role='img' aria-label='Hive project layout'>
<defs>
  <linearGradient id='bg' x1='0' y1='0' x2='1' y2='1'>
    <stop offset='0' stop-color='#0a1c14'/><stop offset='1' stop-color='#06100b'/>
  </linearGradient>
</defs>
<rect width='$W' height='$H' rx='16' fill='url(#bg)' stroke='#1f3a2e'/>
<polygon points='44,44 30,52 16,44 16,28 30,20 44,28' fill='#ffb23d' fill-opacity='0.18' stroke='#e8c170' stroke-width='2'/>
<circle cx='30' cy='36' r='4' fill='#e8c170'/>
<text x='62' y='42' font-family='Segoe UI,sans-serif' font-weight='800' font-size='22' fill='#e8f1ec'>Hive &#183; Project layout</text>
<text x='560' y='42' font-family='Segoe UI,sans-serif' font-size='13' fill='#37d39a'>Microsoft 365 Copilot &#183; Enterprise Agents</text>
<line x1='44' y1='62' x2='$($W-44)' y2='62' stroke='#1f3a2e' stroke-width='1'/>
$($body.ToString())
</svg>
"@

$out = Join-Path $PSScriptRoot 'project-layout.svg'
$svg | Out-File -FilePath $out -Encoding utf8
Write-Host "Wrote $out ($H px tall)"

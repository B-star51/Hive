# HiveHtmlReport.ps1
# Renders a Get-HiveReport object as a self-contained, styled HTML dashboard.
# No external assets or internet needed - ideal for a demo video or sharing.

function New-HiveHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Report,
        [Parameter(Mandatory)][string]$Path
    )

    function Enc([string]$s) { [System.Net.WebUtility]::HtmlEncode($s) }
    function SevClass([string]$s) {
        switch ($s) { 'Critical' {'crit'} 'High' {'high'} 'Medium' {'med'} default {'low'} }
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append(@"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hive - Privilege Escalation Watchdog</title>
<style>
  :root{--bg:#0b1410;--panel:#11201a;--line:#1f3a2e;--ink:#e8f1ec;--mut:#8aa79a;
        --crit:#ff5d5d;--high:#ff9e3d;--med:#ffd23d;--low:#7a8f86;--accent:#37d39a;}
  *{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--ink);
    font:15px/1.5 'Segoe UI',system-ui,sans-serif}
  header{padding:28px 32px;border-bottom:1px solid var(--line);
    background:linear-gradient(180deg,#0d1a14,#0b1410)}
  h1{margin:0;font-size:22px;letter-spacing:.5px}
  h1 span{color:var(--accent)} .sub{color:var(--mut);margin-top:4px;font-size:13px}
  .wrap{padding:24px 32px;max-width:1100px;margin:0 auto}
  .meta{display:flex;gap:24px;flex-wrap:wrap;color:var(--mut);font-size:13px;margin-bottom:20px}
  .meta b{color:var(--ink)}
  h2{font-size:14px;text-transform:uppercase;letter-spacing:1px;color:var(--mut);
     border-bottom:1px solid var(--line);padding-bottom:8px;margin:28px 0 14px}
  .card{background:var(--panel);border:1px solid var(--line);border-radius:12px;
        padding:18px 20px;margin-bottom:14px}
  .card.esc{border-color:var(--crit);box-shadow:0 0 0 1px rgba(255,93,93,.25)}
  .row{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:999px;text-transform:uppercase}
  .crit{background:rgba(255,93,93,.15);color:var(--crit)}
  .high{background:rgba(255,158,61,.15);color:var(--high)}
  .med{background:rgba(255,210,61,.15);color:var(--med)}
  .low{background:rgba(122,143,134,.18);color:var(--low)}
  .ent{font-size:18px;font-weight:700} .score{margin-left:auto;color:var(--mut);font-size:13px}
  .score b{color:var(--ink);font-size:16px}
  .chips{margin:10px 0 4px} .chip{display:inline-block;background:#0e2a20;border:1px solid var(--line);
    color:var(--accent);font-size:12px;padding:2px 8px;border-radius:6px;margin:2px 4px 2px 0}
  .chain{margin-top:14px;border-left:2px solid var(--line);padding-left:16px}
  .step{margin:0 0 12px;position:relative}
  .step::before{content:'';position:absolute;left:-22px;top:5px;width:9px;height:9px;
    border-radius:50%;background:var(--accent)}
  .step .t{color:var(--mut);font-size:12px} .step .ttl{font-weight:600}
  .step .tech{color:var(--accent);font-size:12px}
  .acts{margin:12px 0 0;padding-left:18px} .acts li{margin:4px 0;color:#cfe0d8}
  table{width:100%;border-collapse:collapse;font-size:13px}
  th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line)}
  th{color:var(--mut);text-transform:uppercase;font-size:11px;letter-spacing:.5px}
  .foot{color:var(--mut);font-size:12px;margin-top:30px;text-align:center}
</style></head><body>
<header><h1>HIVE <span>// Privilege Escalation Watchdog</span></h1>
<div class="sub">Multi-agent detection across hybrid identity &middot; advisory-only</div></header>
<div class="wrap">
"@)

    [void]$sb.Append(("<div class='meta'><div>Generated <b>{0}</b></div><div>Source <b>{1}</b></div><div>Events <b>{2}</b></div><div>Incidents <b>{3}</b></div></div>" -f `
        (Enc $Report.generatedAt), (Enc $Report.dataSource), $Report.eventCount, $Report.incidents.Count))

    # ---- Incidents ----
    [void]$sb.Append("<h2>Correlated incidents</h2>")
    foreach ($i in ($Report.incidents | Sort-Object score -Descending)) {
        $esc = if ($i.escalated) { ' esc' } else { '' }
        $tag = if ($i.escalated) { 'ESCALATED' } else { 'watch' }
        [void]$sb.Append("<div class='card$esc'><div class='row'>")
        [void]$sb.Append(("<span class='badge {0}'>{1}</span>" -f (SevClass $i.severity), (Enc $i.severity)))
        [void]$sb.Append(("<span class='ent'>{0}</span>" -f (Enc $i.entity)))
        [void]$sb.Append(("<span class='badge low'>{0}</span>" -f $tag))
        [void]$sb.Append(("<span class='score'>risk score <b>{0}</b> &middot; {1} agents</span></div>" -f $i.score, ($i.agentsFired.Count)))

        if ($i.tactics) {
            [void]$sb.Append("<div class='chips'>")
            foreach ($t in $i.tactics) { [void]$sb.Append("<span class='chip'>$(Enc $t)</span>") }
            [void]$sb.Append("</div>")
        }
        if ($i.attackChain) {
            [void]$sb.Append("<div class='chain'>")
            foreach ($s in $i.attackChain) {
                $tm = ([datetime]$s.time).ToString('HH:mm')
                [void]$sb.Append(("<div class='step'><div class='t'>{0}</div><div class='ttl'>{1}</div><div class='tech'>{2} &middot; {3}</div></div>" -f `
                    $tm, (Enc $s.step), (Enc $s.technique), (Enc $s.tactic)))
            }
            [void]$sb.Append("</div>")
        }

        $resp = $Report.responses | Where-Object { $_.entity -eq $i.entity } | Select-Object -First 1
        if ($resp) {
            [void]$sb.Append("<ul class='acts'>")
            foreach ($a in $resp.recommendedActions) { [void]$sb.Append("<li>$(Enc $a)</li>") }
            [void]$sb.Append("</ul>")
        }
        [void]$sb.Append("</div>")
    }

    # ---- Signals table ----
    [void]$sb.Append("<h2>Agent signals</h2><div class='card'><table><tr><th>Time</th><th>Sev</th><th>Rule</th><th>ATT&CK</th><th>Detection</th><th>Entity</th></tr>")
    foreach ($s in ($Report.signals | Sort-Object timestamp)) {
        $tm = ([datetime]$s.timestamp).ToString('HH:mm')
        [void]$sb.Append(("<tr><td>{0}</td><td><span class='badge {1}'>{2}</span></td><td>{3}</td><td>{4}</td><td>{5}</td><td>{6}</td></tr>" -f `
            $tm, (SevClass $s.severity), (Enc $s.severity), (Enc $s.ruleId), (Enc $s.mitreTechnique), (Enc $s.title), (Enc $s.entity)))
    }
    [void]$sb.Append("</table></div>")

    [void]$sb.Append("<div class='foot'>Hive is advisory-only. Recommended actions require human approval. Built for Microsoft 365 Copilot.</div></div></body></html>")

    $sb.ToString() | Out-File -FilePath $Path -Encoding utf8
    return $Path
}

# ===== Keyboard API =====
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Keyboard {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);

    public const int KEYEVENTF_EXTENDEDKEY = 0x1;
    public const int KEYEVENTF_KEYUP = 0x2;
}
"@

function Toggle-NumLock {
    $VK_NUMLOCK = 0x90
    [Keyboard]::keybd_event($VK_NUMLOCK, 0x45, [Keyboard]::KEYEVENTF_EXTENDEDKEY, 0)
    [Keyboard]::keybd_event($VK_NUMLOCK, 0x45, ([Keyboard]::KEYEVENTF_EXTENDEDKEY -bor [Keyboard]::KEYEVENTF_KEYUP), 0)
}

# ===== 简写映射 =====
$targets = @{
    "GPT" = "https://chat.openai.com"
    "CLD" = "https://claude.ai"
    "GEM" = "https://gemini.google.com"
    "POE" = "https://poe.com"
    "PPL" = "https://www.perplexity.ai"
    "KIM" = "https://kimi.moonshot.cn"
    "TY"  = "https://tongyi.aliyun.com"
    "YY"  = "https://yiyan.baidu.com"
    "DB"  = "https://www.doubao.com"
    "YB"  = "https://yuanbao.tencent.com"
    "DS"  = "https://chat.deepseek.com"
}

while ($true) {
    Clear-Host

    # ===== Keep Alive =====
    $numlock = [console]::NumberLock
    Toggle-NumLock
    Start-Sleep -Milliseconds 120
    if ($numlock) { Toggle-NumLock }

    # ===== Time =====
    $cnTime = Get-Date -Format "HH:mm:ss"

    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("Europe/Rome")
    } catch {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
    }

    $itTime = [System.TimeZoneInfo]::ConvertTimeFromUtc(
        (Get-Date).ToUniversalTime(), $tz
    ).ToString("HH:mm:ss")

    # ===== Header =====
    Write-Host "SYSTEM STATUS"
    Write-Host "CN:$cnTime  EU:$itTime"
    Write-Host "--------------------------------"
    Write-Host "NODE   STATE    LAT(ms)"
    Write-Host "--------------------------------"

    foreach ($node in $targets.Keys) {
        $url = $targets[$node]

        try {
            $start = Get-Date
            $resp = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
            $latency = [int]((Get-Date) - $start).TotalMilliseconds

            if ($resp.StatusCode -eq 200 -and $resp.Content.Length -gt 500) {
                $state = "OK"
            } else {
                $state = "SLOW"
            }
        }
        catch {
            $state = "DOWN"
            $latency = 0
        }

        Write-Host ("{0,-5} {1,-7} {2,6}" -f $node, $state, $latency)
    }

    Write-Host "--------------------------------"

    Start-Sleep -Seconds 300
}
[CmdletBinding()]
param(
    [string]$GodotPath = "",
    [switch]$IncludeMimo,
    [switch]$SkipPythonTests
)

$ErrorActionPreference = "Stop"
$projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$repositoryPath = (Resolve-Path (Join-Path $projectPath "..")).Path

function Resolve-GodotExecutable {
    param([string]$RequestedPath)

    if ($RequestedPath -ne "") {
        if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
            throw "Godot executable was not found at '$RequestedPath'."
        }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    if ($env:GODOT_PATH -ne "" -and (Test-Path -LiteralPath $env:GODOT_PATH -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $env:GODOT_PATH).Path
    }

    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -ne $godotCommand) {
        return $godotCommand.Source
    }

    throw "Godot executable was not found. Pass -GodotPath or set GODOT_PATH."
}

$godot = Resolve-GodotExecutable -RequestedPath $GodotPath
Write-Host "Running Starcat Godot runtime smoke test with $godot"
& $godot --headless --path $projectPath --script res://tools/runtime_smoke_test.gd
if ($LASTEXITCODE -ne 0) {
    throw "Godot runtime smoke test failed with exit code $LASTEXITCODE."
}

if ($IncludeMimo) {
    if ($env:MIMO_API_KEY -eq "") {
        throw "MIMO_API_KEY is required when -IncludeMimo is set."
    }
    Write-Host "Running optional MiMo provider smoke test"
    & $godot --headless --path $projectPath --script res://tools/mimo_provider_smoke_test.gd
    if ($LASTEXITCODE -ne 0) {
        throw "MiMo provider smoke test failed with exit code $LASTEXITCODE."
    }
}

if (-not $SkipPythonTests) {
    Write-Host "Running repository regression tests"
    Push-Location $repositoryPath
    try {
        python -m unittest tests.test_godot_backend_migration
        if ($LASTEXITCODE -ne 0) {
            throw "Repository regression tests failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "STARCAT_GODOT_CHECKS_OK"

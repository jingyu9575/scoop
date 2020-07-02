# Usage: scoop cleanup <app> [options]
# Summary: Cleanup apps by removing old caches
# Help: 'scoop cleanup <app>' cleans up the old caches of that app.
#
# You can use '*' in place of <app> to cleanup all apps.
#
# Options:
#   -g, --global       Cleanup a globally installed app
#   -k, --cache        Remove outdated download cache
#   -t, --temp         Remove temporary files

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\manifest.ps1"
. "$psscriptroot\..\lib\buckets.ps1"
. "$psscriptroot\..\lib\versions.ps1"
. "$psscriptroot\..\lib\getopt.ps1"
. "$psscriptroot\..\lib\help.ps1"
. "$psscriptroot\..\lib\install.ps1"

reset_aliases

$opt, $apps, $err = getopt $args 'gkt' 'global', 'cache', 'temp'
if ($err) { "scoop cleanup: $err"; exit 1 }
$global = $opt.g -or $opt.global
$cache = $opt.k -or $opt.cache
$temp = $opt.t -or $opt.temp

if ($global -and !(is_admin)) {
    'ERROR: you need admin rights to cleanup global apps'; exit 1
}

function cleanup($app, $global, $verbose, $cache) {
    $current_version = current_version $app $global
    if ($cache) {
        Remove-Item "$cachedir\$app#*" -Exclude "$app#$current_version#*"
    }
}

$verbose = $true
if ($apps -eq '*') {
    $verbose = $false
    $apps = applist (installed_apps $false) $false
    if ($global) {
        $apps += applist (installed_apps $true) $true
    }
} elseif ($apps) {
    $apps = Confirm-InstallationStatus $apps -Global:$global
}

# $apps is now a list of ($app, $global) tuples
$apps | ForEach-Object { cleanup @_ $verbose $cache }

if ($cache) {
    Remove-Item "$cachedir\*.download" -ErrorAction Ignore
}

if ($temp) {
    $tempdir = tempdir $global
    if (Test-Path $tempdir) {
        Get-ChildItem $tempdir | ForEach-Object {
            $item = $_.FullName
            try {
                Remove-Item $item -Recurse -Force -ErrorAction Stop
            } catch {
                warn "Couldn't remove '$(friendly_path $item)'; it may be in use."
            }
        }
    }
}

if (!$verbose) {
    success 'Everything is shiny now!'
}

exit 0

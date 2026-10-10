# ============================================================================
#  fedora-gaming - vm-test/test-vm.ps1
#  Banc d'essai VirtualBox (Windows / PowerShell) : teste install.sh dans une
#  VM Fedora KDE AVANT de toucher a la vraie machine. Equivalent de test-vm.sh.
#
#  Usage :
#    .\test-vm.ps1 download    # telecharge l'ISO netinstall Fedora (~900 Mo)
#    .\test-vm.ps1 create      # cree la VM + install unattendue KDE (20-40 min)
#    .\test-vm.ps1 status      # etat de la VM
#    .\test-vm.ps1 wait-ready  # attend que la VM installee soit joignable en SSH
#    .\test-vm.ps1 run         # copie le projet + lance install.sh DANS la VM
#    .\test-vm.ps1 ssh "cmd"   # shell (ou commande) dans la VM
#    .\test-vm.ps1 destroy     # supprime la VM et son disque (garde l'ISO)
#
#  Variables : FEDORA_VER (defaut 43), VM_USER (guill), VM_PW, VM_GUI=1
#  Identifiants VM (test uniquement) : guill / osgaming2026
#  Prerequis : VirtualBox 7.x, OpenSSH client Windows (ssh/scp), tar.exe
#  NB : fichier volontairement sans accents (PowerShell 5.1 lit en ANSI).
# ============================================================================
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("download", "create", "status", "wait-ready", "run", "ssh", "destroy", "help")]
    [string]$Command = "help",
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs
)
# "Continue" : en PS 5.1, "Stop" transforme la progression de VBoxManage
# (ecrite sur stderr) en erreur fatale. Les echecs passent par Fail.
$ErrorActionPreference = "Continue"

$VM_NAME     = "fedora-gaming-test"
$PROJECT_DIR = Split-Path -Parent $PSScriptRoot
# Donnees VM HORS de Documents (la protection des dossiers bloque les ecritures).
$VM_DIR      = Join-Path $env:USERPROFILE "VirtualBox VMs\$VM_NAME"
$ISO_DIR     = Join-Path $env:USERPROFILE "Downloads\fedora-gaming-iso"
# VBox 7.2 ne connait pas F44 en unattended : on valide sur F43
# (install.sh est version-agnostique).
$FEDORA_VER  = if ($env:FEDORA_VER) { $env:FEDORA_VER } else { "43" }
$VM_USER     = if ($env:VM_USER) { $env:VM_USER } else { "guill" }
# Mot de passe de TEST uniquement : VM locale en NAT, jamais exposee.
$VM_PW       = if ($env:VM_PW) { $env:VM_PW } else { "osgaming2026" }
$SSH_PORT    = 2222
$KNOWN_HOSTS = Join-Path $VM_DIR "known_hosts"

# --- VBoxManage : PATH ou chemin d'installation par defaut -----------------
$VB = (Get-Command VBoxManage.exe -ErrorAction SilentlyContinue).Source
if (-not $VB) { $VB = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" }
if (-not (Test-Path $VB)) { Write-Host "VBoxManage introuvable - installe VirtualBox 7.x." -ForegroundColor Red; exit 1 }
$VBOX_DIR = Split-Path -Parent $VB

foreach ($d in $VM_DIR, $ISO_DIR) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Write-Step { param([string]$t) Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }
function Write-Ok   { param([string]$t) Write-Host "  [OK] $t" -ForegroundColor Green }
function Write-Warn { param([string]$t) Write-Host "  [!] $t" -ForegroundColor Yellow }
function Fail       { param([string]$t) Write-Host "  [ERREUR] $t" -ForegroundColor Red; exit 1 }

# VBoxManage : sortie (stderr compris) affichee telle quelle, code retour verifie
function Invoke-Vb {
    & $VB @args 2>&1 | ForEach-Object { Write-Host "    $_" }
    if ($LASTEXITCODE -ne 0) { Fail "VBoxManage $($args[0]) a echoue (code $LASTEXITCODE)." }
}

function Get-VmState {
    $line = & $VB showvminfo $VM_NAME --machinereadable 2>$null | Where-Object { $_ -like "VMState=*" }
    if ($line) { return ($line -split "=", 2)[1].Trim('"') }
    return "inconnu"
}

function Test-VmExists {
    & $VB showvminfo $VM_NAME *> $null
    return ($LASTEXITCODE -eq 0)
}

function Test-SshPort {
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $ar = $c.BeginConnect("127.0.0.1", $SSH_PORT, $null, $null)
        if ($ar.AsyncWaitHandle.WaitOne(1000, $false) -and $c.Connected) { $c.EndConnect($ar); return $true }
        return $false
    } catch { return $false } finally { $c.Close() }
}

function Get-LocalIso {
    $f = Get-ChildItem -Path $ISO_DIR -Filter "Fedora-Everything-netinst-x86_64-$FEDORA_VER-*.iso" -File -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($f) { return $f.FullName }
    return $null
}

# --- SSH sans saisie manuelle (askpass force, OpenSSH >= 8.4) ---------------
function Set-Askpass {
    # Chemin SANS espace : ssh.exe lance l askpass via cmd et coupe aux espaces
    $dir = Join-Path $env:LOCALAPPDATA "fedora-gaming-vmtest"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $askpass = Join-Path $dir "askpass.cmd"
    [System.IO.File]::WriteAllText($askpass, "@echo $VM_PW`r`n", [System.Text.Encoding]::ASCII)
    $env:SSH_ASKPASS = $askpass
    $env:SSH_ASKPASS_REQUIRE = "force"
}

$SSH_OPTS = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=$KNOWN_HOSTS", "-o", "ConnectTimeout=10")

function Invoke-VmSsh {
    param([string]$RemoteCmd)
    Set-Askpass
    & ssh.exe -p $SSH_PORT @SSH_OPTS "$VM_USER@127.0.0.1" $RemoteCmd
    if ($LASTEXITCODE -ne 0) { throw "Commande distante en echec ($LASTEXITCODE) : $RemoteCmd" }
}

# --- Commandes ---------------------------------------------------------------
function Do-Download {
    # ISO netinstall "Everything" : les ISO Live (KDE...) ne sont pas supportees
    # par l'install unattended de VirtualBox. Plasma est installe par fedora-ks.cfg.
    Write-Step "ISO Fedora $FEDORA_VER netinstall (Everything)"
    $iso = Get-LocalIso
    if ($iso) { Write-Ok "ISO deja presente : $iso"; return }
    $mirrors = @("https://dl.fedoraproject.org/pub/fedora/linux/releases", "https://mirrors.kernel.org/fedora/releases")
    $found = $null
    foreach ($m in $mirrors) {
        $u = "$m/$FEDORA_VER/Everything/x86_64/iso/"
        try {
            $html = (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 15).Content
            if ($html -match 'href="(?<n>Fedora-Everything-netinst[^"]*\.iso)"') { $found = $u + $Matches["n"]; break }
        } catch { }
    }
    if (-not $found) { Fail "ISO netinstall Fedora $FEDORA_VER introuvable sur les miroirs." }
    $dest = Join-Path $ISO_DIR ([System.IO.Path]::GetFileName($found))
    Write-Host "Telechargement de $found ..."
    Start-BitsTransfer -Source $found -Destination $dest -DisplayName "Fedora netinstall ISO"
    Write-Ok "ISO telechargee : $dest"
}

function Do-Create {
    Write-Step "Creation de la VM $VM_NAME"
    $iso = Get-LocalIso
    if (-not $iso) { Fail "Pas d'ISO - lance d'abord : .\test-vm.ps1 download" }
    if (Test-VmExists) { Fail "La VM $VM_NAME existe deja - .\test-vm.ps1 destroy pour repartir de zero." }
    Write-Ok "ISO : $iso"

    Write-Host "Config : 4 vCPU, 8 Go RAM, 60 Go, EFI, NAT $SSH_PORT -> 22"
    Invoke-Vb createvm --name $VM_NAME --ostype Fedora_64 --register --basefolder (Split-Path -Parent $VM_DIR)
    Invoke-Vb modifyvm $VM_NAME --memory 8192 --cpus 4 --vram 128 --firmware efi `
        --graphicscontroller vmsvga --audio-driver none `
        --nic1 nat --nat-pf1 "ssh,tcp,,$SSH_PORT,,22" `
        --boot1 dvd --boot2 disk --boot3 none --boot4 none
    $vdi = Join-Path $VM_DIR "$VM_NAME.vdi"
    Invoke-Vb createmedium disk --filename $vdi --size 61440 --variant standard
    Invoke-Vb storagectl $VM_NAME --name SATA --add sata --controller IntelAHCI --bootable on
    Invoke-Vb storageattach $VM_NAME --storagectl SATA --port 0 --device 0 --type hdd --medium $vdi
    Invoke-Vb storageattach $VM_NAME --storagectl SATA --port 1 --device 0 --type dvddrive --medium $iso

    $pw = Join-Path $VM_DIR "vm-password.txt"
    [System.IO.File]::WriteAllText($pw, $VM_PW, [System.Text.Encoding]::ASCII)
    # Kickstart du projet (celui livre avec VBox est obsolete pour Fedora recente).
    # VBox passe "ks=" (ignore par Anaconda recent) : on force "inst.ks=".
    $ksTpl = Join-Path $PSScriptRoot "fedora-ks.cfg"
    $mode = if ($env:VM_GUI -eq "1") { "gui" } else { "headless" }

    Write-Step "Installation sans intervention (~15-25 min, mode $mode)"
    Invoke-Vb unattended install $VM_NAME --iso="$iso" --user="$VM_USER" `
        --full-user-name="Fedora Gaming Test" --password-file="$pw" `
        --hostname="fedora-test.local" --time-zone="Europe/Paris" --locale="fr_FR" `
        --script-template="$ksTpl" --start-vm=$mode `
        --extra-install-kernel-parameters="inst.ks=cdrom:/ks.cfg inst.text"
    Write-Ok "Installation lancee (paquets telecharges depuis les miroirs : 20-40 min)."
    Write-Host "Ensuite : .\test-vm.ps1 wait-ready   puis   .\test-vm.ps1 run"
}

function Do-Status {
    Write-Step "Etat de la VM $VM_NAME"
    if (-not (Test-VmExists)) { Write-Host "VM $VM_NAME : inexistante"; return }
    Write-Host "VM $VM_NAME : $(Get-VmState)"
    if (Test-SshPort) { Write-Ok "SSH (port $SSH_PORT) : joignable" }
    else { Write-Warn "SSH (port $SSH_PORT) : non joignable (install en cours ou VM eteinte)" }
}

function Do-WaitReady {
    Write-Step "Attente du SSH de la VM (jusqu'a 45 min)"
    for ($i = 1; $i -le 90; $i++) {
        if (Test-SshPort) {
            Write-Host ""
            Write-Ok "SSH joignable - VM prete. Prochaine etape : .\test-vm.ps1 run"
            return
        }
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 30
    }
    Write-Host ""
    Fail "Toujours pas de SSH apres 45 min - verifie : .\test-vm.ps1 status"
}

function Do-Run {
    if (-not (Test-SshPort)) { Fail "SSH non joignable - attends la fin de l'install : .\test-vm.ps1 wait-ready" }

    Write-Step "sudo sans mot de passe (uniquement dans la VM de test)"
    # Pas de guillemets doubles imbriques : PS 5.1 les retire en passant a ssh.exe
    Invoke-VmSsh "echo '$VM_PW' | sudo -S sh -c 'echo %wheel ALL=NOPASSWD: ALL > /etc/sudoers.d/99-vmtest && chmod 440 /etc/sudoers.d/99-vmtest'"

    Write-Step "Copie du projet dans la VM"
    # Archive puis scp : le pipe binaire PowerShell 5.1 corromprait le tar.
    $tgz = Join-Path $env:TEMP "fedora-gaming-vmtest.tgz"
    # tar de Windows (bsdtar) : celui de Git, s il est dans le PATH, lit "C:" comme un hote
    & (Join-Path $env:SystemRoot "System32\tar.exe") -czf $tgz --exclude=.git --exclude=NUL -C $PROJECT_DIR .
    if ($LASTEXITCODE -ne 0) { Fail "Creation de l'archive en echec." }
    Set-Askpass
    & scp.exe -P $SSH_PORT @SSH_OPTS $tgz "$VM_USER@127.0.0.1:/tmp/fedora-gaming.tgz"
    if ($LASTEXITCODE -ne 0) { Fail "scp en echec." }
    Remove-Item $tgz -Force
    Invoke-VmSsh "rm -rf ~/fedora-gaming && mkdir -p ~/fedora-gaming && tar xzf /tmp/fedora-gaming.tgz -C ~/fedora-gaming && rm /tmp/fedora-gaming.tgz"

    Write-Step "install.sh dans la VM (plusieurs minutes)"
    Invoke-VmSsh "cd ~/fedora-gaming && ASSUME_YES=1 bash install.sh"
    Write-Ok "Termine - verifie avec : .\test-vm.ps1 ssh ""bash ~/fedora-gaming/doctor.sh"""
}

function Do-Ssh {
    if (-not (Test-SshPort)) { Write-Warn "Le port SSH $SSH_PORT ne semble pas encore ouvert." }
    Set-Askpass
    & ssh.exe -p $SSH_PORT @SSH_OPTS "$VM_USER@127.0.0.1" @CommandArgs
}

function Do-Destroy {
    Write-Step "Suppression de la VM $VM_NAME"
    if (Test-VmExists) {
        if ((Get-VmState) -notin "poweroff", "aborted") {
            & $VB controlvm $VM_NAME poweroff 2>&1 | Out-Null
            # attendre que VirtualBox libere la session avant de supprimer
            for ($i = 0; $i -lt 30 -and (Get-VmState) -notin "poweroff", "aborted"; $i++) { Start-Sleep -Seconds 1 }
            Start-Sleep -Seconds 2
        }
        Invoke-Vb unregistervm $VM_NAME --delete
    }
    Remove-Item (Join-Path $env:LOCALAPPDATA "fedora-gaming-vmtest") -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($f in "vm-password.txt", "askpass.cmd", "known_hosts") {
        $p = Join-Path $VM_DIR $f
        if (Test-Path $p) { Remove-Item $p -Force }
    }
    Write-Ok "VM $VM_NAME supprimee (ISO conservee dans $ISO_DIR)."
}

switch ($Command) {
    "download"   { Do-Download }
    "create"     { Do-Create }
    "status"     { Do-Status }
    "wait-ready" { Do-WaitReady }
    "run"        { Do-Run }
    "ssh"        { Do-Ssh }
    "destroy"    { Do-Destroy }
    default      { Get-Content $PSCommandPath -TotalCount 18 | Select-Object -Skip 1 | ForEach-Object { $_ -replace '^#\s{0,2}', '' } }
}

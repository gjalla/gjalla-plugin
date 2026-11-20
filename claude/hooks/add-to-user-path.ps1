# Adds a directory to the Windows user PATH, once: add-to-user-path.ps1 <dir>
# Run by gjalla-install.sh after it installs gjalla.exe, so git hooks and new terminals find it.
# Reads the raw value (unexpanded, so entries like %USERPROFILE%\bin survive), writes it back as REG_EXPAND_SZ,
# then broadcasts WM_SETTINGCHANGE so Explorer and new processes see the change without a sign-out.
param([Parameter(Mandatory = $true)][string]$Dir)
$ErrorActionPreference = 'Stop'

$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
try {
  $path = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
  $entries = $path -split ';' | Where-Object { $_ }
  if ($entries | Where-Object { $_.TrimEnd('\') -ieq $Dir.TrimEnd('\') }) { exit 0 }
  $key.SetValue('Path', (@($entries) + $Dir) -join ';', [Microsoft.Win32.RegistryValueKind]::ExpandString)
} finally {
  $key.Close()
}

Add-Type -Namespace Gjalla -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
  uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
$result = [UIntPtr]::Zero
# HWND_BROADCAST, WM_SETTINGCHANGE, SMTO_ABORTIFHUNG, 5 s
[Gjalla.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null

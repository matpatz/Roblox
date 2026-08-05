import crypto from "crypto";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const supaUrl = process.env.supabaseurl;
  const serviceKey = process.env.supabaseService;
  const linkvertiseToken = process.env.linkvertiseAb;

  if (!supaUrl || !serviceKey || !linkvertiseToken) {
    console.error('Missing server config:', { supaUrl: !!supaUrl, serviceKey: !!serviceKey, linkvertiseToken: !!linkvertiseToken });
    return res.status(500).json({ error: "Server config missing", detail: { supaUrl: !!supaUrl, serviceKey: !!serviceKey, linkvertiseToken: !!linkvertiseToken } });
  }

  const { hash } = req.body;
  if (!hash || hash.length !== 64) {
    return res.status(403).json({ error: "Invalid hash length" });
  }

  try {
    const verifyUrl = `https://publisher.linkvertise.com/api/v1/anti_bypassing?token=${encodeURIComponent(linkvertiseToken)}&hash=${encodeURIComponent(hash)}`;
    const verifyResp = await fetch(verifyUrl, {
      headers: {
        Accept: 'text/plain, application/json',
        'User-Agent': 'VoltexHub-Server/1.0'
      }
    });
    const verifyText = await verifyResp.text();
    const vt = verifyText.trim();
    console.log("Linkvertise status:", verifyResp.status);
    console.log("Linkvertise raw response:", vt);
    
    let isValid = false;
    if (vt.toLowerCase() === "true" || vt === "TRUE" || vt === "1" || /\btrue\b/i.test(vt)) {
      isValid = true;
    } else {
      try {
        const jsonData = JSON.parse(vt);
        if (typeof jsonData === "boolean") {
          isValid = jsonData === true;
        } else if (jsonData && (jsonData.status === true || jsonData.valid === true || jsonData.success === true)) {
          isValid = true;
        }
      } catch (e) {
        console.log("Parse failed for Linkvertise response:", e);
      }
    }
    
    if (!isValid) {
      return res.status(403).json({ 
        error: "linkvertise_failed", 
        message: "Complete the ad properly (disable VPN/adblock)",
        detail: { status: verifyResp.status, body: vt }
      });
    }
  } catch (e) {
    console.error("Linkvertise fetch error:", e);
    return res.status(500).json({ error: "Linkvertise verification failed" });
  }

  // 2. IP Rate Limiting (2 keys/day)
  const clientIp = req.headers['cf-connecting-ip'] || 
                   req.headers['x-forwarded-for']?.split(",")[0]?.trim() || 
                   req.connection?.remoteAddress || 
                   req.socket.remoteAddress || "unknown";
  const today = new Date().toISOString().split("T")[0];
  
  console.log(`Request from IP: ${clientIp} | Date: ${today}`);

  let keysUsed = 0;
  try {
    const checkResp = await fetch(`${supaUrl}/rest/v1/user_limits?ip=eq.${encodeURIComponent(clientIp)}&date=eq.${today}`, {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`
      }
    });
    
    if (checkResp.ok) {
      const limits = await checkResp.json();
      keysUsed = limits.length > 0 ? limits[0].keys_used : 0;
      console.log(`Keys used today by ${clientIp}: ${keysUsed}`);
    }
    
    if (keysUsed >= 2) {
      return res.status(429).json({ 
        error: "daily_limit_reached",
        message: "Max 2 keys per day per IP. Try tomorrow!",
        keys_used: keysUsed,
        keys_remaining: 0
      });
    }
  } catch (e) {
    console.error("Rate limit check failed:", e);
  }

  const key = crypto.randomUUID().replace(/-/g, "").toUpperCase().slice(0, 32);
  const expires = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  try {
    const keyResp = await fetch(`${supaUrl}/rest/v1/keys`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        Prefer: "return=minimal"
      },
      body: JSON.stringify({ 
        key, 
        expires_at: expires, 
        used: false, 
        created_ip: clientIp 
      })
    });

    if (!keyResp.ok) {
      const errText = await keyResp.text();
      console.error("Key insert failed:", errText);
      return res.status(500).json({ 
        error: "database_insert_failed", 
        message: "Key storage failed, try again",
        detail: errText 
      });
    }

    const newKeysUsed = keysUsed + 1;
    await fetch(`${supaUrl}/rest/v1/user_limits`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        Prefer: "resolution=merge-duplicates"
      },
      body: JSON.stringify({ 
        ip: clientIp, 
        date: today, 
        keys_used: newKeysUsed 
      })
    });

    console.log(`Key generated: ${key} | Remaining: ${2 - newKeysUsed} | IP: ${clientIp}`);
    
    return res.status(200).json({ 
      success: true,
      key, 
      expires_at: expires, 
      keys_remaining: 2 - newKeysUsed 
    });

  } catch (e) {
    console.error("Final generation error:", e);
    return res.status(500).json({ 
      error: "generation_failed", 
      message: "Unexpected server error"
    });
  }
}
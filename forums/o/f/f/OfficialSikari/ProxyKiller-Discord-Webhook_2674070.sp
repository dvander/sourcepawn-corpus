#include <json>
#include <ProxyKiller>

#pragma dynamic 131072

char gC_WebhookUrl[MAX_CONFIG_VARIABLE_VALUE];
char gC_GeoIPWebsite[MAX_CONFIG_VARIABLE_VALUE];

public void OnPluginStart()
{
	if (ProxyKiller_Config_IsInit())
	{
		ProxyKiller_OnConfig();
	}
}

public void ProxyKiller_OnConfig()
{
	if (!ProxyKiller_Config_GetVariable("discord_webhook_url", gC_WebhookUrl, sizeof(gC_WebhookUrl)))
	{
		SetFailState("Cannot find webhook url (\"discord_webhook_url\") from ProxyKiller config!");
	}

	if (!ProxyKiller_Config_GetVariable("discord_webhook_geoip", gC_GeoIPWebsite, sizeof(gC_GeoIPWebsite)))
	{
		gC_GeoIPWebsite = "http://geoiplookup.net/ip/";
	}
}

public void ProxyKiller_OnClientResult(ProxyUser pUser, bool result, bool fromCache)
{
	if (!result) return;
	if (fromCache) return;

	ProxyHTTP http = ProxyKiller_CreateHTTP(gC_WebhookUrl, HTTPMethod_POST);

	char name[MAX_NAME_LENGTH];
	pUser.GetName(name, sizeof(name));

	char steamId2[32];
	pUser.GetSteamId2(steamId2, sizeof(steamId2));

	char steamId64[24];
	pUser.GetSteamId64(steamId64, sizeof(steamId64));

	char ipAddress[16];
	pUser.GetIPAddress(ipAddress, sizeof(ipAddress));

	char desc[256];
	Format(desc, sizeof(desc), "[Steam Profile](https://steamcommunity.com/profiles/%s) \
								\n[IP Location & Details](%s%s)", steamId64, gC_GeoIPWebsite, ipAddress);

	char dateTime[32];
	FormatTime(dateTime, sizeof(dateTime), "%FT%T%z", GetTime());

	JSON_Object hMain = new JSON_Object(false);
	hMain.SetObject("embeds", new JSON_Object(true));

	JSON_Object hEmbed = new JSON_Object(false);
	hEmbed.SetString("color", "2888657");
	hEmbed.SetString("description", desc);
	hEmbed.SetString("timestamp", dateTime);
	hEmbed.SetString("title", "New VPN/Proxy connection!");
	hEmbed.SetObject("fields", new JSON_Object(true));

	JSON_Object hSteamIdField = new JSON_Object(false);
	hSteamIdField.SetString("name", "Player IP Address");
	hSteamIdField.SetString("value", ipAddress);
	hSteamIdField.SetBool("inline", true);
	hEmbed.GetObject("fields").PushObject(hSteamIdField);

	JSON_Object hIPAddressField = new JSON_Object(false);
	hIPAddressField.SetString("name", "Player SteamId2");
	hIPAddressField.SetString("value", steamId2);
	hIPAddressField.SetBool("inline", true);
	hEmbed.GetObject("fields").PushObject(hIPAddressField);
	
	JSON_Object hNameField = new JSON_Object(false);
	hNameField.SetString("name", "Player Name");
	hNameField.SetString("value", name);
	hNameField.SetBool("inline", false);
	hEmbed.GetObject("fields").PushObject(hNameField);

	hEmbed.SetObject("footer", new JSON_Object(false));
	hEmbed.GetObject("footer").SetString("text", "Detected by ProxyKiller");

	hMain.GetObject("embeds").PushObject(hEmbed);

	char json[1024];
	hMain.Encode(json, sizeof(json));

	hMain.Cleanup();
	delete hMain;

	http.SetRawBody(json);
	ProxyKiller_SendHTTPRequest(http, OnWebhookSent);
}

public void OnWebhookSent(ProxyHTTPResponse response, const char[] responseData)
{
	if (response.Failure)
	{
		LogError("Failed to POST webhook, status: %d", response.Status);
	}
}
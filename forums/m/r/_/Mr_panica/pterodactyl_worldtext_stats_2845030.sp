#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>

/*
 * Minimal JSON declarations copied from:
 * include/ripext/json.inc
 * Source: Ripext JSON include used by this plugin for JSONObject parsing.
 */
methodmap JSON < Handle
{
};

methodmap JSONObject < JSON
{
	public static native JSONObject FromString(const char[] buffer, int flags = 0);
	public native JSON Get(const char[] key);
	public native float GetFloat(const char[] key);
	public native bool GetString(const char[] key, char[] buffer, int maxlength);
	public native bool HasKey(const char[] key);
};

#define PLUGIN_VERSION "1.0.0"
#define CONFIG_RELATIVE_PATH "configs/pterodactyl_worldtext_stats.cfg"
#define WORLDTEXT_LINES 14
#define POLL_INTERVAL_SECONDS 20.0
#define DISPLAY_UPDATE_INTERVAL 0.1

enum WorldTextSlot
{
	Slot_Header = 0,
	Slot_Blank,
	Slot_UptimeLabel,
	Slot_UptimeValue,
	Slot_CpuLabel,
	Slot_CpuValue,
	Slot_MemoryLabel,
	Slot_MemoryValue,
	Slot_NetworkInLabel,
	Slot_NetworkInValue,
	Slot_NetworkOutLabel,
	Slot_NetworkOutValue,
	Slot_NextRequestLabel,
	Slot_NextRequestValue
};

ConVar g_cvServerId;
ConVar g_cvPosX;
ConVar g_cvPosY;
ConVar g_cvPosZ;
ConVar g_cvAngPitch;
ConVar g_cvAngYaw;
ConVar g_cvAngRoll;
ConVar g_cvFont;
ConVar g_cvTextSize;
ConVar g_cvOrientation;
ConVar g_cvColor;
ConVar g_cvTargetName;
ConVar g_cvDebug;
ConVar g_cvLineSpacing;

Handle g_hApiTimer = null;
Handle g_hDisplayTimer = null;
Handle g_hRequest = INVALID_HANDLE;
int g_iWorldTextRefs[WORLDTEXT_LINES];

bool g_bConfigLoaded = false;
bool g_bRequestPending = false;
bool g_bHaveNetworkBaseline = false;
float g_flLastRxBytes = 0.0;
float g_flLastTxBytes = 0.0;
float g_flLastSampleTime = 0.0;
float g_flLastInboundRate = 0.0;
float g_flLastOutboundRate = 0.0;
float g_flNextPollTime = 0.0;

char g_sBaseUrl[256];
char g_sApiKey[256];

public Plugin myinfo =
{
	name = "Pterodactyl WorldText Stats",
	author = "Codex",
	description = "Shows Pterodactyl server resource usage via point_worldtext",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	g_cvServerId = CreateConVar("sm_ptero_stats_server_id", "", "Pterodactyl server identifier.", FCVAR_NONE);
	g_cvPosX = CreateConVar("sm_ptero_stats_x", "0.0", "WorldText X position.", FCVAR_NONE);
	g_cvPosY = CreateConVar("sm_ptero_stats_y", "0.0", "WorldText Y position.", FCVAR_NONE);
	g_cvPosZ = CreateConVar("sm_ptero_stats_z", "0.0", "WorldText Z position.", FCVAR_NONE);
	g_cvAngPitch = CreateConVar("sm_ptero_stats_pitch", "0.0", "WorldText pitch angle.", FCVAR_NONE);
	g_cvAngYaw = CreateConVar("sm_ptero_stats_yaw", "90.0", "WorldText yaw angle.", FCVAR_NONE);
	g_cvAngRoll = CreateConVar("sm_ptero_stats_roll", "90.0", "WorldText roll angle.", FCVAR_NONE);
	g_cvFont = CreateConVar("sm_ptero_stats_font", "8", "point_worldtext font.", FCVAR_NONE);
	g_cvTextSize = CreateConVar("sm_ptero_stats_textsize", "8", "point_worldtext text size.", FCVAR_NONE);
	g_cvOrientation = CreateConVar("sm_ptero_stats_orientation", "0", "point_worldtext orientation.", FCVAR_NONE);
	g_cvColor = CreateConVar("sm_ptero_stats_color", "255 255 255 255", "point_worldtext RGBA color.", FCVAR_NONE);
	g_cvTargetName = CreateConVar("sm_ptero_stats_targetname", "ptero_stats_worldtext", "point_worldtext targetname.", FCVAR_NONE);
	g_cvDebug = CreateConVar("sm_ptero_stats_debug", "0", "Enable debug logging for Pterodactyl stats plugin.", FCVAR_NONE);
	g_cvLineSpacing = CreateConVar("sm_ptero_stats_line_spacing", "8.0", "Vertical spacing between point_worldtext lines.", FCVAR_NONE);

	AutoExecConfig(true, "pterodactyl_worldtext_stats");
	ResetWorldTextRefs();
}

public void OnConfigsExecuted()
{
	LoadApiConfig();
	ResetNetworkBaseline();
	EnsureWorldTextEntity();
	UpdateUnavailableText();
	RestartTimers();
}

public void OnMapStart()
{
	ResetWorldTextRefs();
	EnsureWorldTextEntity();
	UpdateUnavailableText();
	RestartTimers();
}

public void OnMapEnd()
{
	StopTimers();
	ResetWorldTextRefs();
	g_bRequestPending = false;
}

public void OnPluginEnd()
{
	StopTimers();
	RemoveWorldTextEntity();
	ClosePendingRequest();
}

void LoadApiConfig()
{
	g_bConfigLoaded = false;
	g_sBaseUrl[0] = '\0';
	g_sApiKey[0] = '\0';

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_RELATIVE_PATH);

	if (!FileExists(path))
	{
		LogError("[PteroStats] Config file not found: %s", path);
		return;
	}

	KeyValues kv = new KeyValues("PterodactylWorldTextStats");
	if (!kv.ImportFromFile(path))
	{
		LogError("[PteroStats] Failed to import config file: %s", path);
		delete kv;
		return;
	}

	kv.GetString("base_url", g_sBaseUrl, sizeof(g_sBaseUrl), "");
	kv.GetString("api_key", g_sApiKey, sizeof(g_sApiKey), "");
	delete kv;

	TrimString(g_sBaseUrl);
	TrimString(g_sApiKey);
	TrimTrailingSlash(g_sBaseUrl);

	if (!g_sBaseUrl[0] || !g_sApiKey[0])
	{
		LogError("[PteroStats] base_url or api_key is empty in %s", path);
		return;
	}

	g_bConfigLoaded = true;
}

void RestartTimers()
{
	StopTimers();
	g_flNextPollTime = 0.0;
	g_hDisplayTimer = CreateTimer(DISPLAY_UPDATE_INTERVAL, Timer_UpdateDisplay, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	g_hApiTimer = CreateTimer(POLL_INTERVAL_SECONDS, Timer_RequestStats, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	RequestStats();
}

void StopTimers()
{
	if (g_hApiTimer != null)
	{
		KillTimer(g_hApiTimer);
		g_hApiTimer = null;
	}

	if (g_hDisplayTimer != null)
	{
		KillTimer(g_hDisplayTimer);
		g_hDisplayTimer = null;
	}
}

public Action Timer_RequestStats(Handle timer)
{
	RequestStats();
	return Plugin_Continue;
}

public Action Timer_UpdateDisplay(Handle timer)
{
	UpdateNextRequestText(GetEngineTime());
	return Plugin_Continue;
}

void RequestStats()
{
	if (g_bRequestPending)
	{
		DebugLog("Skipping poll tick because previous request is still pending.");
		return;
	}

	if (!g_bConfigLoaded || !SteamWorks_IsLoaded())
	{
		g_flNextPollTime = GetEngineTime() + POLL_INTERVAL_SECONDS;
		UpdateUnavailableText();
		return;
	}

	char serverId[128];
	g_cvServerId.GetString(serverId, sizeof(serverId));
	TrimString(serverId);

	if (!serverId[0])
	{
		g_flNextPollTime = GetEngineTime() + POLL_INTERVAL_SECONDS;
		UpdateUnavailableText();
		return;
	}

	RequestStatsRoute(serverId);
}

void RequestStatsRoute(const char[] serverId)
{
	char url[512];
	char authHeader[320];

	FormatEx(url, sizeof(url), "%s/api/client/servers/%s/resources?_=%d", g_sBaseUrl, serverId, GetTime());
	FormatEx(authHeader, sizeof(authHeader), "Bearer %s", g_sApiKey);

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	if (request == INVALID_HANDLE)
	{
		LogError("[PteroStats] Failed to create SteamWorks HTTP request.");
		g_flNextPollTime = GetEngineTime() + POLL_INTERVAL_SECONDS;
		UpdateUnavailableText();
		return;
	}

	SteamWorks_SetHTTPRequestHeaderValue(request, "Authorization", authHeader);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Accept", "application/vnd.pterodactyl.v1+json");
	SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/json");
	SteamWorks_SetHTTPRequestHeaderValue(request, "Cache-Control", "no-cache, no-store, must-revalidate");
	SteamWorks_SetHTTPRequestHeaderValue(request, "Pragma", "no-cache");
	SteamWorks_SetHTTPRequestHeaderValue(request, "Expires", "0");
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 2);
	SteamWorks_SetHTTPRequestAbsoluteTimeoutMS(request, 2000);
	SteamWorks_SetHTTPCallbacks(request, OnStatsResponse);

	DebugLog("Requesting %s", url);
	g_bRequestPending = true;
	g_flNextPollTime = GetEngineTime() + POLL_INTERVAL_SECONDS;
	g_hRequest = request;
	SteamWorks_SendHTTPRequest(request);
}

public void OnStatsResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode statusCode)
{
	g_bRequestPending = false;
	g_hRequest = INVALID_HANDLE;

	if (bFailure || !bRequestSuccessful)
	{
		LogError("[PteroStats] SteamWorks request failed. Failure=%d, Successful=%d, Status=%d", bFailure, bRequestSuccessful, statusCode);
		UpdateUnavailableText();
		CloseHandle(request);
		return;
	}

	if (statusCode != k_EHTTPStatusCode200OK)
	{
		LogError("[PteroStats] API request failed. HTTP %d.", statusCode);
		UpdateUnavailableText();
		CloseHandle(request);
		return;
	}

	int bodySize = 0;
	if (!SteamWorks_GetHTTPResponseBodySize(request, bodySize) || bodySize <= 0)
	{
		LogError("[PteroStats] Failed to get HTTP response body size.");
		UpdateUnavailableText();
		CloseHandle(request);
		return;
	}

	char[] body = new char[bodySize + 1];
	if (!SteamWorks_GetHTTPResponseBodyData(request, body, bodySize))
	{
		LogError("[PteroStats] Failed to read HTTP response body.");
		UpdateUnavailableText();
		CloseHandle(request);
		return;
	}

	body[bodySize] = '\0';
	CloseHandle(request);

	JSONObject root = JSONObject.FromString(body);
	if (root == null)
	{
		LogError("[PteroStats] Failed to parse JSON response body.");
		UpdateUnavailableText();
		return;
	}

	JSONObject attributes = view_as<JSONObject>(root.Get("attributes"));
	JSONObject resources = null;

	if (attributes != null)
	{
		resources = view_as<JSONObject>(attributes.Get("resources"));
	}

	if (resources == null)
	{
		LogError("[PteroStats] Response JSON does not contain resources/utilization object.");
		delete root;
		UpdateUnavailableText();
		return;
	}

	float uptimeMs = JsonGetNumber(resources, "uptime", -1.0);
	float cpuAbsolute = JsonGetNumber(resources, "cpu_absolute", -1.0);
	float memoryBytes = JsonGetNumber(resources, "memory_bytes", -1.0);
	float rxBytes = JsonGetNumber(resources, "network_rx_bytes", -1.0);
	float txBytes = JsonGetNumber(resources, "network_tx_bytes", -1.0);
	float sampleTime = GetEngineTime();

	if (uptimeMs < 0.0 || cpuAbsolute < 0.0 || memoryBytes < 0.0 || rxBytes < 0.0 || txBytes < 0.0)
	{
		LogError("[PteroStats] Response JSON is missing one or more resource fields.");
		delete root;
		UpdateUnavailableText();
		return;
	}

	float inboundPerSecond = g_flLastInboundRate;
	float outboundPerSecond = g_flLastOutboundRate;

	if (g_bHaveNetworkBaseline)
	{
		float rxDelta = rxBytes - g_flLastRxBytes;
		float txDelta = txBytes - g_flLastTxBytes;

		if (rxDelta < 0.0)
		{
			rxDelta = 0.0;
		}

		if (txDelta < 0.0)
		{
			txDelta = 0.0;
		}

		if (rxDelta > 0.0 || txDelta > 0.0)
		{
			float elapsed = sampleTime - g_flLastSampleTime;
			if (elapsed < 0.001)
			{
				elapsed = 1.0;
			}

			inboundPerSecond = rxDelta / elapsed;
			outboundPerSecond = txDelta / elapsed;
			g_flLastInboundRate = inboundPerSecond;
			g_flLastOutboundRate = outboundPerSecond;
		}
	}

	g_flLastRxBytes = rxBytes;
	g_flLastTxBytes = txBytes;
	g_flLastSampleTime = sampleTime;
	g_bHaveNetworkBaseline = true;

	char uptimeText[64];
	char cpuText[32];
	char memoryText[32];
	char inboundText[32];
	char outboundText[32];
	char uptimeColor[32];
	char cpuColor[32];
	char memoryColor[32];
	char networkInColor[32];
	char networkOutColor[32];
	char defaultColor[32];

	FormatUptime(uptimeMs, uptimeText, sizeof(uptimeText));
	FormatEx(cpuText, sizeof(cpuText), "%.1f%%", cpuAbsolute);
	FormatMegabytes(memoryBytes, memoryText, sizeof(memoryText));
	FormatKilobytes(inboundPerSecond, inboundText, sizeof(inboundText));
	FormatKilobytes(outboundPerSecond, outboundText, sizeof(outboundText));
	GetUptimeColor(uptimeColor, sizeof(uptimeColor));
	GetCpuColor(cpuAbsolute, cpuColor, sizeof(cpuColor));
	GetMemoryColor(memoryBytes, memoryColor, sizeof(memoryColor));
	GetNetworkColor(inboundPerSecond, networkInColor, sizeof(networkInColor));
	GetNetworkColor(outboundPerSecond, networkOutColor, sizeof(networkOutColor));
	g_cvColor.GetString(defaultColor, sizeof(defaultColor));

	delete root;
	DebugLog("Updated stats: uptime=%s cpu=%.1f memory_bytes=%.0f rx_delta=%.0f tx_delta=%.0f", uptimeText, cpuAbsolute, memoryBytes, inboundPerSecond, outboundPerSecond);
	SetWorldTextLine(Slot_Header, "Server Statistics", defaultColor);
	SetWorldTextLine(Slot_Blank, " ", defaultColor);
	SetWorldTextLine(Slot_UptimeLabel, "Uptime:", defaultColor);
	SetWorldTextLine(Slot_UptimeValue, "%s", uptimeColor, uptimeText);
	SetWorldTextLine(Slot_CpuLabel, "CPU Load:", defaultColor);
	SetWorldTextLine(Slot_CpuValue, "%s", cpuColor, cpuText);
	SetWorldTextLine(Slot_MemoryLabel, "Memory:", defaultColor);
	SetWorldTextLine(Slot_MemoryValue, "%s", memoryColor, memoryText);
	SetWorldTextLine(Slot_NetworkInLabel, "Network Inbound:", defaultColor);
	SetWorldTextLine(Slot_NetworkInValue, "%s/s", networkInColor, inboundText);
	SetWorldTextLine(Slot_NetworkOutLabel, "Network Outbound:", defaultColor);
	SetWorldTextLine(Slot_NetworkOutValue, "%s/s", networkOutColor, outboundText);
	SetWorldTextLine(Slot_NextRequestLabel, "Next Request:", defaultColor);
	UpdateNextRequestText(GetEngineTime());
}

float JsonGetNumber(JSONObject jsonObject, const char[] key, float fallback)
{
	if (jsonObject == null)
	{
		return fallback;
	}

	if (jsonObject.HasKey(key))
	{
		return jsonObject.GetFloat(key);
	}

	char value[64];
	if (!jsonObject.GetString(key, value, sizeof(value)))
	{
		return fallback;
	}

	TrimString(value);
	if (!value[0])
	{
		return fallback;
	}

	return StringToFloat(value);
}

void ClosePendingRequest()
{
	if (g_hRequest != INVALID_HANDLE)
	{
		CloseHandle(g_hRequest);
		g_hRequest = INVALID_HANDLE;
	}
}

void EnsureWorldTextEntity()
{
	for (int i = 0; i < WORLDTEXT_LINES; i++)
	{
		int entity = GetWorldTextEntity(i);
		if (entity == -1)
		{
			entity = FindWorldTextByTargetName(i);
			if (entity == -1)
			{
				entity = CreateEntityByName("point_worldtext");
				if (entity == -1)
				{
					LogError("[PteroStats] Failed to create point_worldtext.");
					return;
				}

				ApplyWorldTextProperties(entity, i);
				DispatchSpawn(entity);
				ActivateEntity(entity);
				g_iWorldTextRefs[i] = EntIndexToEntRef(entity);
				continue;
			}

			g_iWorldTextRefs[i] = EntIndexToEntRef(entity);
		}

		ApplyWorldTextProperties(entity, i);
	}
}

void ApplyWorldTextProperties(int entity, int lineIndex)
{
	char targetName[64];
	char font[16];
	char textSize[16];
	char orientation[16];
	float origin[3];
	float angles[3];
	float right[3];
	float lineSpacing = g_cvLineSpacing.FloatValue;

	FormatTargetName(lineIndex, targetName, sizeof(targetName));
	g_cvFont.GetString(font, sizeof(font));
	g_cvTextSize.GetString(textSize, sizeof(textSize));
	g_cvOrientation.GetString(orientation, sizeof(orientation));

	origin[0] = g_cvPosX.FloatValue;
	origin[1] = g_cvPosY.FloatValue;
	angles[0] = g_cvAngPitch.FloatValue;
	angles[1] = g_cvAngYaw.FloatValue;
	angles[2] = g_cvAngRoll.FloatValue;
	GetAngleVectors(angles, NULL_VECTOR, right, NULL_VECTOR);

	int row = GetWorldTextRow(lineIndex);
	origin[2] = g_cvPosZ.FloatValue - (float(row) * lineSpacing);

	if (IsValueSlot(lineIndex))
	{
		float valueOffset = GetValueOffset(lineIndex);
		origin[0] += right[0] * valueOffset;
		origin[1] += right[1] * valueOffset;
		origin[2] += right[2] * valueOffset;
	}

	DispatchKeyValue(entity, "targetname", targetName);
	DispatchKeyValue(entity, "font", font);
	DispatchKeyValue(entity, "textsize", textSize);
	DispatchKeyValue(entity, "orientation", orientation);
	DispatchKeyValueVector(entity, "angles", angles);
	TeleportEntity(entity, origin, angles, NULL_VECTOR);
}

void UpdateUnavailableText()
{
	char defaultColor[32];
	g_cvColor.GetString(defaultColor, sizeof(defaultColor));
	SetWorldTextLine(Slot_Header, "Server Statistics", defaultColor);
	SetWorldTextLine(Slot_Blank, " ", defaultColor);
	SetWorldTextLine(Slot_UptimeLabel, "Uptime:", defaultColor);
	SetWorldTextLine(Slot_UptimeValue, "unavailable", defaultColor);
	SetWorldTextLine(Slot_CpuLabel, "CPU Load:", defaultColor);
	SetWorldTextLine(Slot_CpuValue, "unavailable", defaultColor);
	SetWorldTextLine(Slot_MemoryLabel, "Memory:", defaultColor);
	SetWorldTextLine(Slot_MemoryValue, "unavailable", defaultColor);
	SetWorldTextLine(Slot_NetworkInLabel, "Network Inbound:", defaultColor);
	SetWorldTextLine(Slot_NetworkInValue, "unavailable", defaultColor);
	SetWorldTextLine(Slot_NetworkOutLabel, "Network Outbound:", defaultColor);
	SetWorldTextLine(Slot_NetworkOutValue, "unavailable", defaultColor);
	SetWorldTextLine(Slot_NextRequestLabel, "Next Request:", defaultColor);
	UpdateNextRequestText(GetEngineTime());
}

void SetWorldTextLine(int lineIndex, const char[] text, const char[] color, any ...)
{
	EnsureWorldTextEntity();

	int entity = GetWorldTextEntity(lineIndex);
	if (entity == -1)
	{
		return;
	}

	char message[256];
	VFormat(message, sizeof(message), text, 4);

	SetWorldTextColor(lineIndex, color);
	DispatchKeyValue(entity, "message", message);
	SetVariantString(message);
	AcceptEntityInput(entity, "SetText");

	if (message[0] == '\0')
	{
		AcceptEntityInput(entity, "Disable");
	}
	else
	{
		AcceptEntityInput(entity, "Enable");
	}
}

void SetWorldTextColor(int lineIndex, const char[] color)
{
	EnsureWorldTextEntity();

	int entity = GetWorldTextEntity(lineIndex);
	if (entity == -1)
	{
		return;
	}

	DispatchKeyValue(entity, "color", color);
	ApplyEntityColor(entity, color);
}

int FindWorldTextByTargetName(int lineIndex)
{
	char targetName[64];
	FormatTargetName(lineIndex, targetName, sizeof(targetName));

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "point_worldtext")) != -1)
	{
		char entityTargetName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", entityTargetName, sizeof(entityTargetName));
		if (StrEqual(entityTargetName, targetName))
		{
			return entity;
		}
	}

	return -1;
}

int GetWorldTextEntity(int lineIndex)
{
	int entity = EntRefToEntIndex(g_iWorldTextRefs[lineIndex]);
	return entity == INVALID_ENT_REFERENCE ? -1 : entity;
}

void RemoveWorldTextEntity()
{
	for (int i = 0; i < WORLDTEXT_LINES; i++)
	{
		int entity = GetWorldTextEntity(i);
		if (entity != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}

	ResetWorldTextRefs();
}

void ResetWorldTextRefs()
{
	for (int i = 0; i < WORLDTEXT_LINES; i++)
	{
		g_iWorldTextRefs[i] = INVALID_ENT_REFERENCE;
	}
}

void ResetNetworkBaseline()
{
	g_bHaveNetworkBaseline = false;
	g_flLastRxBytes = 0.0;
	g_flLastTxBytes = 0.0;
	g_flLastSampleTime = 0.0;
	g_flLastInboundRate = 0.0;
	g_flLastOutboundRate = 0.0;
	g_flNextPollTime = 0.0;
}

void TrimTrailingSlash(char[] value)
{
	int length = strlen(value);
	while (length > 0 && value[length - 1] == '/')
	{
		value[length - 1] = '\0';
		length--;
	}
}

void FormatUptime(float uptimeMs, char[] buffer, int maxlength)
{
	int totalSeconds = RoundToFloor(uptimeMs / 1000.0);
	int days = totalSeconds / 86400;
	int hours = (totalSeconds % 86400) / 3600;
	int minutes = (totalSeconds % 3600) / 60;
	int seconds = totalSeconds % 60;

	if (days > 0)
	{
		FormatEx(buffer, maxlength, "%dd %02dh %02dm %02ds", days, hours, minutes, seconds);
	}
	else if (hours > 0)
	{
		FormatEx(buffer, maxlength, "%dh %02dm %02ds", hours, minutes, seconds);
	}
	else
	{
		FormatEx(buffer, maxlength, "%dm %02ds", minutes, seconds);
	}
}

void FormatMegabytes(float bytes, char[] buffer, int maxlength)
{
	float value = bytes / 1024.0 / 1024.0;
	FormatEx(buffer, maxlength, "%.1f MB", value);
}

void FormatKilobytes(float bytes, char[] buffer, int maxlength)
{
	float value = bytes / 1024.0;
	FormatEx(buffer, maxlength, "%.1f KB", value);
}

void GetUptimeColor(char[] buffer, int maxlength)
{
	strcopy(buffer, maxlength, "120 255 120 255");
}

void GetCpuColor(float cpuAbsolute, char[] buffer, int maxlength)
{
	if (cpuAbsolute <= 30.0)
	{
		strcopy(buffer, maxlength, "120 255 120 255");
		return;
	}

	if (cpuAbsolute <= 60.0)
	{
		strcopy(buffer, maxlength, "255 220 96 255");
		return;
	}

	strcopy(buffer, maxlength, "255 80 80 255");
}

void GetMemoryColor(float memoryBytes, char[] buffer, int maxlength)
{
	float memoryMiB = memoryBytes / 1024.0 / 1024.0;

	if (memoryMiB <= 800.0)
	{
		strcopy(buffer, maxlength, "120 255 120 255");
		return;
	}

	if (memoryMiB <= 1500.0)
	{
		strcopy(buffer, maxlength, "255 220 96 255");
		return;
	}

	strcopy(buffer, maxlength, "255 80 80 255");
}

void GetNetworkColor(float bytesPerSecond, char[] buffer, int maxlength)
{
	float kilobytesPerSecond = bytesPerSecond / 1024.0;

	if (kilobytesPerSecond <= 64.0)
	{
		strcopy(buffer, maxlength, "120 255 120 255");
		return;
	}

	if (kilobytesPerSecond <= 256.0)
	{
		strcopy(buffer, maxlength, "255 220 96 255");
		return;
	}

	strcopy(buffer, maxlength, "255 80 80 255");
}

void FormatTargetName(int lineIndex, char[] buffer, int maxlength)
{
	char baseTargetName[64];
	g_cvTargetName.GetString(baseTargetName, sizeof(baseTargetName));
	FormatEx(buffer, maxlength, "%s_%d", baseTargetName, lineIndex);
}

int GetWorldTextRow(int lineIndex)
{
	switch (lineIndex)
	{
		case Slot_Header:
		{
			return 0;
		}
		case Slot_Blank:
		{
			return 1;
		}
		case Slot_UptimeLabel, Slot_UptimeValue:
		{
			return 2;
		}
		case Slot_CpuLabel, Slot_CpuValue:
		{
			return 3;
		}
		case Slot_MemoryLabel, Slot_MemoryValue:
		{
			return 4;
		}
		case Slot_NetworkInLabel, Slot_NetworkInValue:
		{
			return 5;
		}
		case Slot_NetworkOutLabel, Slot_NetworkOutValue:
		{
			return 6;
		}
		case Slot_NextRequestLabel, Slot_NextRequestValue:
		{
			return 7;
		}
	}

	return lineIndex;
}

bool IsValueSlot(int lineIndex)
{
	switch (lineIndex)
	{
		case Slot_UptimeValue, Slot_CpuValue, Slot_MemoryValue, Slot_NetworkInValue, Slot_NetworkOutValue:
		{
			return true;
		}
		case Slot_NextRequestValue:
		{
			return true;
		}
	}

	return false;
}

void UpdateNextRequestText(float now)
{
	char defaultColor[32];
	char countdown[32];
	g_cvColor.GetString(defaultColor, sizeof(defaultColor));

	float remaining = g_flNextPollTime - now;
	if (g_flNextPollTime <= 0.0 || remaining < 0.0)
	{
		remaining = 0.0;
	}

	FormatEx(countdown, sizeof(countdown), "%.1fs", remaining);
	SetWorldTextLine(Slot_NextRequestValue, "%s", defaultColor, countdown);
}

float GetValueOffset(int lineIndex)
{
	char label[32];
	float textScale = float(g_cvTextSize.IntValue);
	float gap = textScale * 0.75;
	float charWidth = textScale * 0.60;

	GetLabelTextForValueSlot(lineIndex, label, sizeof(label));
	return (float(strlen(label)) * charWidth) + gap;
}

void GetLabelTextForValueSlot(int lineIndex, char[] buffer, int maxlength)
{
	switch (lineIndex)
	{
		case Slot_UptimeValue:
		{
			strcopy(buffer, maxlength, "Uptime:");
		}
		case Slot_CpuValue:
		{
			strcopy(buffer, maxlength, "CPU Load:");
		}
		case Slot_MemoryValue:
		{
			strcopy(buffer, maxlength, "Memory:");
		}
		case Slot_NetworkInValue:
		{
			strcopy(buffer, maxlength, "Network Inbound:");
		}
		case Slot_NetworkOutValue:
		{
			strcopy(buffer, maxlength, "Network Outbound:");
		}
		case Slot_NextRequestValue:
		{
			strcopy(buffer, maxlength, "Next Request:");
		}
		default:
		{
			buffer[0] = '\0';
		}
	}
}

void DebugLog(const char[] format, any ...)
{
	if (!g_cvDebug.BoolValue)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogMessage("[PteroStats] %s", buffer);
}

void ApplyEntityColor(int entity, const char[] color)
{
	int rgba[4];
	if (!ParseColorString(color, rgba))
	{
		return;
	}

	SetEntityRenderColor(entity, rgba[0], rgba[1], rgba[2], rgba[3]);
}

bool ParseColorString(const char[] color, int rgba[4])
{
	char parts[4][12];
	int count = ExplodeString(color, " ", parts, sizeof(parts), sizeof(parts[]));
	if (count < 3)
	{
		return false;
	}

	rgba[0] = StringToInt(parts[0]);
	rgba[1] = StringToInt(parts[1]);
	rgba[2] = StringToInt(parts[2]);
	rgba[3] = count >= 4 ? StringToInt(parts[3]) : 255;
	return true;
}

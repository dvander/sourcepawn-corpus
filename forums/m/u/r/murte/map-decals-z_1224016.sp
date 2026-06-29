#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

/*
	zdecal
	darksidebio.com
	20100629
	my first sm mod!
*/

public Plugin:myinfo = {name="", author="z", description="map decals", version="1.0", url="http://darksidebio.com"}

new String:mapname[256];
new String:cfgpath[PLATFORM_MAX_PATH];
new Handle:z_data = INVALID_HANDLE;

public zRefreshDecals() {
	ClearArray(z_data);

	decl String:buffer[PLATFORM_MAX_PATH];
	decl String:download[PLATFORM_MAX_PATH];

	// Find config
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, cfgpath, sizeof(cfgpath), "configs/map-decals-z/%s.cfg", mapname);
	LogMessage("map: %s; cfg: %s", mapname, cfgpath);

	// Load config
	new Handle:kv = CreateKeyValues("Decals");
	FileToKeyValues(kv, cfgpath);

	// Read config
	if (!KvGotoFirstSubKey(kv)) {
		LogMessage("cfg not found: %s", cfgpath);
		CloseHandle(kv);
		return;
	}
	
	do {
		// material name
		KvGetSectionName(kv, buffer, sizeof(buffer));
		
		// PreCache
		new precacheId = PrecacheDecal(buffer, true);
		
		// DOWNLOAD vmt
		Format(download, sizeof(download), "materials/%s.vmt", buffer);
		AddFileToDownloadsTable(download);
		
		// Read vmt to locate vtf
		new Handle:vtf = CreateKeyValues("LightmappedGeneric");
		FileToKeyValues(vtf, download);
		KvGetString(vtf, "$basetexture", buffer, sizeof(buffer), buffer);
		CloseHandle(vtf);
		Format(download, sizeof(download), "materials/%s.vtf", buffer);
		AddFileToDownloadsTable(download);

		// Search for positions
		new Float:position[3];
		decl String:strpos[8];
		new n=1;
		Format(strpos, sizeof(strpos), "pos%d", n);
		KvGetVector(kv, strpos, position);

		while (position[0] + position[1] + position[2] != 0) {
			new Handle:a = CreateArray(4);
			PushArrayCell(a, position[0]);
			PushArrayCell(a, position[1]);
			PushArrayCell(a, position[2]);
			PushArrayCell(a, precacheId);

			PushArrayCell(z_data, a);
			
			Format(strpos, sizeof(strpos), "pos%d", ++n);
			KvGetVector(kv, strpos, position);
		}
		
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
}

public OnClientPostAdminCheck(client) {
	decl Float:position[3];
	decl obj;
	decl Integer:precache;
	
	new size = GetArraySize(z_data);
	for (new i=0; i<size; ++i) {
		obj = GetArrayCell(z_data, i);
		
		position[0] = GetArrayCell(obj, 0);
		position[1] = GetArrayCell(obj, 1);
		position[2] = GetArrayCell(obj, 2);
		
		precache = GetArrayCell(obj, 3);
		
		TE_SetupBSPDecal(position, 0, precache);
		TE_SendToClient(client);
	}
}

public OnPluginStart() {
	LogMessage("map-decal-z load");
	z_data = CreateArray();
}

public OnLibraryRemoved(const String:name[]) {
	LogMessage("map-decal-z unload");
}

public OnMapStart() {
	zRefreshDecals();
}

public OnMapEnd() {
	ClearArray(z_data);
}

TE_SetupBSPDecal(const Float:vecOrigin[3], entity, index) {
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_nEntity",entity);
	TE_WriteNum("m_nIndex",index);
}

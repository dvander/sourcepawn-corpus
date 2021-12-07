



enum {
	x,
	y,
	z
}


enum struct PlayerPosition {
	float world_pos[3];			// x, y, z	player position from world origin.
	float map_pos[3];			// x, y, z	player position on 2D map overview from upper-left corner of 1024 x 1024 dimension.

	float map_scale;			// scale value what we get from map overview resource\overviews\*.txt file
	float map_offset[3];		// x, y, z	map overview offset point from world origin
	bool map_rotate;			// Is Map Rotated by 90 degrees. -Looks like we don't need this for resource\overviews\*.dds pictures.


	// function to update
	void Update()
	{
		// 1. Point from map upper-left corner to -> player world position.
		MakeVectorFromPoints(this.map_offset, this.world_pos, this.map_pos);

		// 2. Invert Y axis, coordinates work on 2D picture (upper-left corner = 0,0)
		this.map_pos[y] = -this.map_pos[y];

		// 3. Scale coordinates to fit 1024 x 1024 picture dimension. All radar pictures what I found are 1024 x 1024
		this.map_pos[x] /= this.map_scale;
		this.map_pos[y] /= this.map_scale;
	}
}


// Array to store PlayerPosition data;
PlayerPosition players_pos[MAXPLAYERS+1];


#include <sdktools>

public void OnPluginStart()
{
	CreateTimer(3.0, timer_update, _, TIMER_REPEAT); // slow timer
	
	RegConsoleCmd("sm_teleportmap", sm_teleportmap, "Give \"x y\" map coordinates (dimension 1024 x 1024)");
}


// update map scale, offset, on map start and all server configure files executed
public void OnConfigsExecuted()
{
	char buffer[PLATFORM_MAX_PATH];

	if( GetCurrentMap(buffer, sizeof(buffer)) <= 0 ) return;

	Format(buffer, sizeof(buffer), "resource/overviews/%s.txt", buffer);

	if(!FileExists(buffer))
	{
		LogError("FileExists: can't find file '%s'", buffer);
	}

	// Load map overview txt file keyvalues
	KeyValues kvOverview = new KeyValues(buffer);
	kvOverview.ImportFromFile(buffer);

	float scale 	= kvOverview.GetFloat("scale", 5.0); // default values will be used if we fail to import txt file to kvOverview.
	float pos_x		= kvOverview.GetFloat("pos_x", -1000.0);
	float pos_y		= kvOverview.GetFloat("pos_y", 1000.0);
	bool rotate		= view_as<bool>(kvOverview.GetNum("rotate", 0));

	delete kvOverview;

	// Update values in PlayerPos players_pos array
	for(int a = 0; a < sizeof(players_pos); a++)
	{
		players_pos[a].map_scale		= scale;
		players_pos[a].map_offset[x]	= pos_x;
		players_pos[a].map_offset[y]	= pos_y;
		players_pos[a].map_rotate		= rotate;
	}
}


public Action timer_update(Handle timer)
{
	// Keep updating players position

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) continue;

		GetClientAbsOrigin(i, players_pos[i].world_pos);
		players_pos[i].Update();
		
		if(IsFakeClient(i)) continue;
		
		
		PrintToServer("\nPlayer %N\n World %.02f %.02f \n   Map %.02f %.02f \noffset %.02f %.02f\n\n",
			i,
			players_pos[i].world_pos[x], players_pos[i].world_pos[y],
			players_pos[i].map_pos[x], players_pos[i].map_pos[y],
			players_pos[i].map_offset[x], players_pos[i].map_offset[y]);
		
	}


	return Plugin_Continue;
}





// command!

public Action sm_teleportmap(int client, int args)
{
	if(client == 0 || !IsClientInGame(client)) return Plugin_Handled;

	if(args <= 1)
	{
		ReplyToCommand(client, "Teleport yourself to x y map coordinates (limit 1024 x 1024). Usage:\nsm_teleportmap 500 500");
		return Plugin_Handled;
	}

	float origin[3];
	GetClientAbsOrigin(client, origin);

	char buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));

	origin[x] = StringToFloat(buffer);
	
	if(origin[x] < 0.0) {
		origin[x] = 0.0;
	}
	else if(origin[x] > 1024.0) {
		origin[x] = 1024.0;
	}

	GetCmdArg(2, buffer, sizeof(buffer));

	origin[y] = StringToFloat(buffer);
	
	if(origin[y] < 0.0) {
		origin[y] = 0.0;
	}
	else if(origin[y] > 1024.0) {
		origin[y] = 1024.0;
	}


	origin[x] *= players_pos[client].map_scale;
	origin[y] *= players_pos[client].map_scale;

	origin[y] = -origin[y]

	AddVectors(origin, players_pos[client].map_offset, origin);

	PrintToConsole(client, "x %f y %f", origin[x], origin[y]);
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);



	return Plugin_Handled;
}

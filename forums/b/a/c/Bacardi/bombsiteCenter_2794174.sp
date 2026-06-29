

#include <sdktools>

enum struct bombsiteinfo
{
	float A[3];
	float B[3];
	float Acustom[3];
	float Bcustom[3];
}
bombsiteinfo bombsite;

ConVar sm_bombsite_swap;
ConVar sm_bombsiteA_pos;
ConVar sm_bombsiteB_pos;


public void OnPluginStart()
{
	sm_bombsite_swap = CreateConVar("sm_bombsite_swap", "0", "Swap bombsite A and B place on radar", _, true, 0.0, true, 1.0);
	sm_bombsiteA_pos = CreateConVar("sm_bombsiteA_pos", "0", "Set custom location for A");
	sm_bombsiteB_pos = CreateConVar("sm_bombsiteB_pos", "0", "Set custom location for B");
}

bool IsBombsiteCenterNull(float vec[3])
{
	if(vec[0] == NULL_VECTOR[0] &&
		vec[1] == NULL_VECTOR[1] &&
		vec[2] == NULL_VECTOR[2])
			return true;

	return false;
}

public void OnMapEnd()
{
	bombsite.A = NULL_VECTOR;
	bombsite.B = NULL_VECTOR;
	bombsite.Acustom = NULL_VECTOR;
	bombsite.Bcustom = NULL_VECTOR;
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));

	Format(buffer, sizeof(buffer), "exec maps/bombsiteplugin.%s.cfg", buffer);
	ServerCommand(buffer);
}

public void OnConfigsExecuted()
{
	char buffer[PLATFORM_MAX_PATH];

	sm_bombsiteA_pos.GetString(buffer, sizeof(buffer));

	if(!StrEqual(buffer, "0", false))
	{
		SetCustomPos(bombsite.Acustom, buffer);
	}


	buffer[0] = '\0';

	sm_bombsiteB_pos.GetString(buffer, sizeof(buffer));

	if(!StrEqual(buffer, "0", false))
	{
		SetCustomPos(bombsite.Bcustom, buffer);
	}
}

void SetCustomPos(float pos[3], const char[] buffer)
{
	char buffers[3][13];
	ExplodeString(buffer, ",", buffers, sizeof(buffers), sizeof(buffers[]));
	
	pos[0] = StringToFloat(buffers[0]);
	pos[1] = StringToFloat(buffers[1]);
	pos[2] = StringToFloat(buffers[2]);
}

public void OnClientConnected(int client)
{
	if(IsBombsiteCenterNull(bombsite.A) && IsBombsiteCenterNull(bombsite.B))
	{
		UpdateBombsites();
	}
}

void UpdateBombsites()
{
	int func_bomb_target = -1;
	int count;
	
	while((func_bomb_target = FindEntityByClassname(func_bomb_target, "func_bomb_target")) != -1)
	{
		count++;
	}

	if(count == 0)
		return;


	int cs_player_manager = FindEntityByClassname(-1, "cs_player_manager");

	if(cs_player_manager != -1)
	{
		if(HasEntProp(cs_player_manager, Prop_Send, "m_bombsiteCenterA"))
		{
			float vec[3];
			GetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterA", vec);

			if(IsBombsiteCenterNull(bombsite.A))
				bombsite.A = vec;

			GetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterB", vec);

			if(IsBombsiteCenterNull(bombsite.B))
				bombsite.B = vec;


			if(sm_bombsite_swap.BoolValue &&
				!IsBombsiteCenterNull(bombsite.A) &&
				!IsBombsiteCenterNull(bombsite.B))
			{
				SetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterA", bombsite.B);
				SetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterB", bombsite.A);
			}

			if(!sm_bombsite_swap.BoolValue && !IsBombsiteCenterNull(bombsite.Acustom))
			{
				SetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterA", bombsite.Acustom);
				//PrintToServer("bombsite.Acustom %f %f %f", bombsite.Acustom[0], bombsite.Acustom[1], bombsite.Acustom[2]);
			}

			if(!sm_bombsite_swap.BoolValue && !IsBombsiteCenterNull(bombsite.Bcustom))
			{
				SetEntPropVector(cs_player_manager, Prop_Send, "m_bombsiteCenterB", bombsite.Bcustom);
				//PrintToServer("bombsite.Bcustom %f %f %f", bombsite.Bcustom[0], bombsite.Bcustom[1], bombsite.Bcustom[2]);
			}
		}
	}
}



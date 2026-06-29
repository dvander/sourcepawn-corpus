#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0.0"

new Handle:h_dissolvetype = INVALID_HANDLE;
new Handle:options = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[ASP] Dissolve Expert",
	author = "Creator by Aurora [Russia], author idea by Jora",
	description = "Эффект исчезновения.",
	version = VERSION,
	url = "post2dim@gmail.com"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	h_dissolvetype = CreateConVar("dissolve_type", "3", "Значение:\n\"1 = Молнии\",\n\"3 = Растворение\",\n\"4 = Растворение с телом\".", FCVAR_PLUGIN);
	options = CreateConVar("options", "1", "Значение:\n\"1 = Исчезновение с эффектом\".\n\"0 = Исчезновение без эффекта\".", FCVAR_PLUGIN);

	AutoExecConfig(true, "dissolve_expert");
}

public OnEntityCreated(entity, const String:classname[])
{
	// Скрипт не будет предпринимать действий, пока не создаться именно npc_.

	decl String:NPClassName[32];
	Format(NPClassName, sizeof(NPClassName), "npc%s", classname[3]);

	if(strcmp(classname, "npc_grenade_frag") == 0 || (strcmp(classname, "npc_satchel") == 0 || (strcmp(classname, "npc_tripmine") == 0)))
	{
		//... если это Граната(npc_grenade_frag).
		//... если это Брошенная Растяжка(npc_satchel).
		//... если это Установленная Растяжка(npc_tripmine).
		//... то ни чего не выполняется.
	}
	else if(strcmp(classname, NPClassName) == 0) // Проверяю, создался ли именно npc_.
	{
		HookEntityOutput(NPClassName, "OnDeath", OnEntityDeath); // Хукаем оутпут.
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	if (client == 0 || ragdoll == -1) return Plugin_Continue;

	if (GetConVarBool(options))
	{
		new String:targetname[32], String:dissolvetype[32];

		Format(targetname, sizeof(targetname), "dis_%d", client);
		Format(dissolvetype, sizeof(dissolvetype), "%d", GetConVarInt(h_dissolvetype));

		new entity = CreateEntityByName("env_entity_dissolver");
		if (entity > 0)
		{
			DispatchKeyValue(ragdoll, "targetname", targetname);
			DispatchKeyValue(entity, "dissolvetype", dissolvetype);
			DispatchKeyValue(entity, "target", targetname);
			AcceptEntityInput(entity, "Dissolve");
			AcceptEntityInput(entity, "kill");
		}
	}
	else
	{
		if (ragdoll > 0)
			AcceptEntityInput(ragdoll, "kill");
	}

	return Plugin_Continue;
}

public OnEntityDeath(const String:output[], entity, activator, Float:delay)
{
	if (!IsValidEdict(entity))
		return;

	new ent = CreateEntityByName("env_entity_dissolver");
	if (ent > 0)
	{
		new String:targetname[32], String:dissolvetype[32];
		GetEntityClassname(entity, targetname, 32);
		Format(targetname, sizeof(targetname), "target_%d", entity);

		DispatchKeyValue(entity, "targetname", targetname);
		DispatchKeyValue(ent, "dissolvetype", dissolvetype);
		DispatchKeyValue(ent, "target", targetname);
		AcceptEntityInput(ent, "Dissolve");
		AcceptEntityInput(ent, "kill");

		UnhookEntityOutput(targetname, "OnDeath", OnEntityDeath); // УнХукаем оутпут.
	}
}


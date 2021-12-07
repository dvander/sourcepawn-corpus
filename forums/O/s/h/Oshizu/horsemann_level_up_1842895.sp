#include <tf2_stocks>
#define HORSEMANN "headless_hatman"

new hhh_level = 1;

public Plugin:myinfo =
{
	name = "[TF2] Headless Horseless Horsemann Levels",
	author = "Oshizu",
	description = "Each time you kill horsemann he levels up. Just like monoculus.",
	version = "1.0.3",
};

public OnPluginStart()
{
	HookEvent("pumpkin_lord_summoned", hhh_spawn);
	HookEvent("pumpkin_lord_killed", hhh_die);
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 3000);
	
	RegAdminCmd("tf_halloween_bot_level_increase", hhh_increase_level, ADMFLAG_GENERIC, "Increases Current Level of Headless Horseless Horseman.");
	RegAdminCmd("tf_halloween_bot_level_decrease", hhh_decrease_level, ADMFLAG_GENERIC, "Decreases Current Level of Headless Horseless Horseman.");
	RegAdminCmd("tf_halloween_bot_level_reset", hhh_reset_level, ADMFLAG_GENERIC, "Resets Current Level of Headless Horseless Horseman back to 1.");
}

public Action:hhh_increase_level(client, args)
{
	hhh_level++
	if(hhh_level < 51)
	{
		PrintToChat(client, "Changed Headless Horseless Horsemann Level To %d!", hhh_level);
	}
	else if(hhh_level > 50)
	{
		hhh_level = 50;
		PrintToChat(client, "Changed Headless Horseless Horsemann Level To %d!", hhh_level);
	}
}

public Action:hhh_decrease_level(client, args)
{
	hhh_level--
	if(hhh_level > 1)
	{
		PrintToChat(client, "Changed Headless Horseless Horsemann Level To %d!", hhh_level);
	}
	else if(hhh_level < 1)
	{
		hhh_level = 1;
		PrintToChat(client, "Changed Headless Horseless Horsemann Level To %d!", hhh_level);
	}
}

public Action:hhh_reset_level(client, args)
{
	hhh_level = 1;
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 3000);
	PrintToChat(client, "Headless Horseless Horsemann Level has been reseted!");
}

public Action:hhh_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("Headless Horseless Horsemann Level %d has appeared!", hhh_level);
}

public Action:hhh_die(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("Headless Horseless Horsemann Level %d has been defeated!", hhh_level);
	hhh_level++
	if(hhh_level == 1)
	{
	}
	else if(hhh_level == 2)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 6000);
	}
	else if(hhh_level == 3)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 6500);
	}
	else if(hhh_level == 4)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 7000);
	}
	else if(hhh_level == 5)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 7500);
	}
	else if(hhh_level == 6)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 8000);
	}
	else if(hhh_level == 7)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 8500);
	}
	else if(hhh_level == 8)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 9000);
	}
	else if(hhh_level == 9)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 9500);
	}
	else if(hhh_level == 10)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 10000);
	}
	else if(hhh_level == 11)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 10500);
	}
	else if(hhh_level == 12)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 11000);
	}
	else if(hhh_level == 13)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 11500);
	}
	else if(hhh_level == 14)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 12000);
	}
	else if(hhh_level == 15)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 12500);
	}
	else if(hhh_level == 16)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 13000);
	}
	else if(hhh_level == 17)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 13500);
	}
	else if(hhh_level == 18)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 14000);
	}
	else if(hhh_level == 19)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 14500);
	}
	else if(hhh_level == 20)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 15000);
	}
	else if(hhh_level == 21)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 15500);
	}
	else if(hhh_level == 22)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 16000);
	}
	else if(hhh_level == 23)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 16500);
	}
	else if(hhh_level == 24)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 17000);
	}
	else if(hhh_level == 25)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 17500);
	}
	else if(hhh_level == 26)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 18000);
	}
	else if(hhh_level == 27)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 18500);
	}
	else if(hhh_level == 28)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 19000);
	}
	else if(hhh_level == 29)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 19500);
	}
	else if(hhh_level == 30)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 20000);
	}
	else if(hhh_level == 31)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 20500);
	}
	else if(hhh_level == 32)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 21000);
	}
	else if(hhh_level == 33)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 21500);
	}
	else if(hhh_level == 34)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 22000);
	}
	else if(hhh_level == 35)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 22500);
	}
	else if(hhh_level == 36)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 23000);
	}
	else if(hhh_level == 37)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 23500);
	}
	else if(hhh_level == 38)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 24000);
	}
	else if(hhh_level == 39)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 24500);
	}
	else if(hhh_level == 40)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 25000);
	}
	else if(hhh_level == 41)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 25500);
	}
	else if(hhh_level == 42)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 26000);
	}
	else if(hhh_level == 43)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 26500);
	}
	else if(hhh_level == 44)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 27000);
	}
	else if(hhh_level == 45)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 27500);
	}
	else if(hhh_level == 46)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 28000);
	}
	else if(hhh_level == 47)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 28500);
	}
	else if(hhh_level == 48)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 29000);
	}
	else if(hhh_level == 49)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 29500);
	}
	else if(hhh_level == 50)
	{
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 30000);
	}
	else if(hhh_level == 51) // When player beats level 50 = final horsemann he gets back to level 1
	{
	hhh_level = 1;
	SetConVarInt(FindConVar("tf_halloween_bot_health_base"), 3000);
	}
}
/*
 * ccbots.sp
 * Copyright (c) 2021 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#define PLUGIN_VERSION		"0.1"
#define PLUGIN_NAME		"[CURE] Bot Management"

#include <sourcemod>

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "EDSHOT",
	description = "Allows players to manage bots without admin",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_addbot", ccbAddBot);
	RegConsoleCmd("sm_kickallbot", ccbKickBots);
	RegConsoleCmd("sm_kickallbots", ccbKickBots);
	RegAdminCmd("sm_wind", ccbMaxBots, ADMFLAG_GENERIC);
}

public Action:ccbAddBot(client, args)
{
	int numOfBots = GetConVarInt(FindConVar("bot_quota"));
	if (numOfBots != 4)
	{
		numOfBots++;
		SetConVarInt(FindConVar("bot_quota"), numOfBots, true, false);
	}
	return Plugin_Handled;
}

public Action:ccbKickBots(client, args)
{
	if (GetConVarInt(FindConVar("bot_quota")) != 0)
	{
		SetConVarInt(FindConVar("bot_quota"), 0, true, false);
	}
	return Plugin_Handled;
}

public Action:ccbMaxBots(client, args)
{
	SetConVarInt(FindConVar("bot_quota"), 4, true, false);
	return Plugin_Handled;
}

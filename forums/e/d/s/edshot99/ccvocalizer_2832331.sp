/*
 * ccvocalizer.sp
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

#include <sourcemod>
#include <sdktools_stringtables>

#define BUFFER_SIZE 32
#define EXTENDED_BUFFER_SIZE 128

Handle hcvAffirmativeSound;
Handle hcvNegativeSound;
Handle hcvThanksSound;
Handle hcvHelpSound;
Handle hcvLetsMoveSound;
Handle hcvHoldupSound;
Handle hcvFallbackSound;
Handle hcvDeployChestSound;
Handle hcvDeploySentrySound;
Handle hcvGrenadeOutSound;
Handle hcvBombArmedSound;

public Plugin:myinfo =
{
	name = "[CURE] Vocalizer",
	author = "EDSHOT",
	description = "Add voice lines for certain actions done (like in Counter-Strike).",
	version = "0.1"
};

public void OnPluginStart()
{
	hcvAffirmativeSound = CreateConVar("sm_ccvocalizer_affirmative", "sound/cs16/ct_affirm.wav");
	hcvNegativeSound = CreateConVar("sm_ccvocalizer_negative", "sound/cs16/negative.wav");
	hcvThanksSound = CreateConVar("sm_ccvocalizer_thanks", "");
	hcvHelpSound = CreateConVar("sm_ccvocalizer_help", "sound/cs16/help.wav");
	hcvLetsMoveSound = CreateConVar("sm_ccvocalizer_letsmove", "sound/cs16/moveout.wav");
	hcvHoldupSound = CreateConVar("sm_ccvocalizer_holdup", "sound/cs16/lets_wait_here.wav");
	hcvFallbackSound = CreateConVar("sm_ccvocalizer_fallback", "sound/cs16/fallback.wav");
	hcvDeployChestSound = CreateConVar("sm_ccvocalizer_deploychest", "");
	hcvDeploySentrySound = CreateConVar("sm_ccvocalizer_deploysentry", "");
	hcvGrenadeOutSound = CreateConVar("sm_ccvocalizer_grenadeout", "sound/cs16/ct_fireinhole.wav");
	hcvBombArmedSound = CreateConVar("sm_ccvocalizer_bombarmed", "sound/cs16/bombpl.wav");

	VocalizerDownload();
	VocalizerPrecache();

	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, false);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessage_TextMsg, false);
}

public void OnPluginEnd()
{
	UnhookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, false);
	UnhookUserMessage(GetUserMessageId("TextMsg"), UserMessage_TextMsg, false);
}

public void VocalizerPrecache()
{
	char buf[BUFFER_SIZE];
	Handle convar;

	for (int i; i <= 10; i++)
	{
		switch (i)
		{
			case 0: convar = hcvAffirmativeSound;
			case 1: convar = hcvNegativeSound;
			case 2: convar = hcvThanksSound;
			case 3: convar = hcvHelpSound;
			case 4: convar = hcvLetsMoveSound;
			case 5: convar = hcvHoldupSound;
			case 6: convar = hcvFallbackSound;
			case 7: convar = hcvDeployChestSound;
			case 8: convar = hcvDeploySentrySound;
			case 9: convar = hcvGrenadeOutSound;
			case 10: convar = hcvBombArmedSound;
		}
		GetConVarString(convar, buf, sizeof(buf));
		if (!(StrEqual(buf, "", false))) PrecacheSound(buf, true);
	}
}

public void VocalizerDownload()
{
	char buf[BUFFER_SIZE];
	Handle convar;

	for (int i; i <= 10; i++)
	{
		switch (i)
		{
			case 0: convar = hcvAffirmativeSound;
			case 1: convar = hcvNegativeSound;
			case 2: convar = hcvThanksSound;
			case 3: convar = hcvHelpSound;
			case 4: convar = hcvLetsMoveSound;
			case 5: convar = hcvHoldupSound;
			case 6: convar = hcvFallbackSound;
			case 7: convar = hcvDeployChestSound;
			case 8: convar = hcvDeploySentrySound;
			case 9: convar = hcvGrenadeOutSound;
			case 10: convar = hcvBombArmedSound;
		}
		GetConVarString(convar, buf, sizeof(buf));
		if (!(StrEqual(buf, "", false))) AddFileToDownloadsTable(buf);
	}
}

public void OnMapStart()
{
	VocalizerDownload();
	VocalizerPrecache();
}

public Action UserMessage_SayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char buf[EXTENDED_BUFFER_SIZE];

	// DEBUG[SayText2]: HL2MP_Chat_All
	BfReadString(msg, buf, sizeof(buf), true);
	// DEBUG[SayText2]: EDSHOT
	BfReadString(msg, buf, sizeof(buf), true);
	// DEBUG[SayText2]: #CC_CO_1
	BfReadString(msg, buf, sizeof(buf), true);

	//PrintToConsoleAll("DEBUG[SayText2]: %s", buf);

	if (StrEqual(buf, "#CC_CO_1", true)) Vocalize(1);
	else if (StrEqual(buf, "#CC_CO_2", true)) Vocalize(2);
	else if (StrEqual(buf, "#CC_CO_3", true)) Vocalize(3);
	else if (StrEqual(buf, "#CC_CO_4", true)) Vocalize(4);
	else if (StrEqual(buf, "#CC_CO_5", true)) Vocalize(5);
	else if (StrEqual(buf, "#CC_CO_6", true)) Vocalize(6);
	else if (StrEqual(buf, "#CC_CO_7", true)) Vocalize(7);
	else if (StrEqual(buf, "#CC_CO_8", true)) Vocalize(8);
	else if (StrEqual(buf, "#CC_CO_9", true)) Vocalize(9);
	else if (StrEqual(buf, "#CC_CO_GREN", true)) Vocalize(10);

	return Plugin_Continue;
}

public Action UserMessage_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char buf[EXTENDED_BUFFER_SIZE];

	// DEBUG[TextMsg]: #CC_PRT_BombArmed
	BfReadString(msg, buf, sizeof(buf), true);

	//PrintToConsoleAll("DEBUG[TextMsg]: %s", buf);

	if (StrEqual(buf, "#CC_PRT_BombArmed", true)) Vocalize(11);

	return Plugin_Continue;
}

public void Vocalize(int voiceline)
{
	char buf[BUFFER_SIZE];

	switch (voiceline)
	{
		case 1: GetConVarString(hcvAffirmativeSound, buf, sizeof(buf));
		case 2: GetConVarString(hcvNegativeSound, buf, sizeof(buf));
		case 3: GetConVarString(hcvThanksSound, buf, sizeof(buf));
		case 4: GetConVarString(hcvHelpSound, buf, sizeof(buf));
		case 5: GetConVarString(hcvLetsMoveSound, buf, sizeof(buf));
		case 6: GetConVarString(hcvHoldupSound, buf, sizeof(buf));
		case 7: GetConVarString(hcvFallbackSound, buf, sizeof(buf));
		case 8: GetConVarString(hcvDeployChestSound, buf, sizeof(buf));
		case 9: GetConVarString(hcvDeploySentrySound, buf, sizeof(buf));
		case 10: GetConVarString(hcvGrenadeOutSound, buf, sizeof(buf));
		case 11: GetConVarString(hcvBombArmedSound, buf, sizeof(buf));
	}
	if (StrEqual(buf, "", false)) return;
	ReplaceString(buf, sizeof(buf), "sound/", "", true);
	//PrintToConsoleAll("DEBUG[Vocalize]: %s", buf);

	for (int p = 1; p <= GetMaxClients(); p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			ClientCommand(p, "play \"%s\"", buf);
		}
	}
}

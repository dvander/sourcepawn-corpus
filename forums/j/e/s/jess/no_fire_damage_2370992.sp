/**
 * =============================================================================
 * No Fire Damage on Friendly-Fire (C)2015 Jessica "jess" Henderson
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = { name = "no friendly fire from fire", author = "https://forums.alliedmods.net/showthread.php?t=275866", description = "fire, canisters, fireworks, etc. don't damage teammates", version = "amphar", url = "https://forums.alliedmods.net/showthread.php?t=275866", };

new Handle:hFriendlyFire;
new Handle:hFriendlyFire_OfFire;

public OnPluginStart() {

	hFriendlyFire = CreateConVar("sm_friendlyfire","1","disabled means no friendly fire.");
	hFriendlyFire_OfFire = CreateConVar("sm_friendlyfire_from_fire","0","disabled means no friendly fire from fire sources.");
}

public OnConfigsExecuted() { AutoExecConfig(true, "friendlyfire_offire"); }

public OnClientPostAdminCheck(client) {

	/*


			When a player has completed authorization and has been cleared
			to enter the server.


	*/
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client) {

	/*


			When a player disconnects, we want to remove the hook.


	*/
	if (client > 0 && IsClientInGame(client)) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {

	if (victim > 0 && attacker > 0 && GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2) {

		/*


				If the person who dealt the damage is a survivor and the person who received the damage
				is a survivor, then we check to see which kind of mitigation we use.
		*/
		if (GetConVarInt(hFriendlyFire) == 0 ||
			GetConVarInt(hFriendlyFire_OfFire) == 0 && (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)) {

			/*


					First statement, if true: Friendly-fire, regardless of damage type is ignored.
					Second statement, if true: Friendly-fire, resulting from explosions/fire is ignored.


			*/
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
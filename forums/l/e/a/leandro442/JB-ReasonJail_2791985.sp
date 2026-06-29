#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#pragma newdecls required

char Razoes_Jail[124][MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateTimer(0.5, Status_player, _, TIMER_REPEAT);
	HookEvent("player_spawn", Event_Spawn_Razoes);
}
public void Event_Spawn_Razoes(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client))
	{
		switch (GetRandomInt(1, 111))
		{
			case 1:
			{
				Razoes_Jail[client] = "Ser Gay";
			}
			case 2:
			{
				Razoes_Jail[client] = "Bater Uma Punheta";
			}
			case 3:
			{
				Razoes_Jail[client] = "Comer Melao";
			}
			case 4:
			{
				Razoes_Jail[client] = "Aprender a Mijar";
			}
			case 5:
			{
				Razoes_Jail[client] = "Aprender a Cagar";
			}
			case 6:
			{
				Razoes_Jail[client] = "Levar no Rabo";
			}
			case 7:
			{
				Razoes_Jail[client] = "Ser Filho da Puta";
			}
			case 8:
			{
				Razoes_Jail[client] = "Ser Paneleiro";
			}
			case 9:
			{
				Razoes_Jail[client] = "Gostar de Pila";
			}
			case 10:
			{
				Razoes_Jail[client] = "Gostar de Vagina";
			}
			case 11:
			{
				Razoes_Jail[client] = "Ter Pila Pequena";
			}
			case 12:
			{
				Razoes_Jail[client] = "Ter Pila Grande";
			}
			case 13:
			{
				Razoes_Jail[client] = "Ser Lesbico";
			}
			case 14:
			{
				Razoes_Jail[client] = "Consumir Drogas";
			}
			case 15:
			{
				Razoes_Jail[client] = "Beber Alcool";
			}
			case 16:
			{
				Razoes_Jail[client] = "Ser Magro";
			}
			case 17:
			{
				Razoes_Jail[client] = "Ser Gordo";
			}
			case 18:
			{
				Razoes_Jail[client] = "Ser Violado";
			}
			case 19:
			{
				Razoes_Jail[client] = "Violar Menores";
			}
			case 20:
			{
				Razoes_Jail[client] = "Conduzir Mal";
			}
			case 21:
			{
				Razoes_Jail[client] = "Conduzir Bem";
			}
			case 22:
			{
				Razoes_Jail[client] = "Meter os Dedos";
			}
			case 23:
			{
				Razoes_Jail[client] = "Roubar um Banco";
			}
			case 24:
			{
				Razoes_Jail[client] = "Roubar uma Loja";
			}
			case 25:
			{
				Razoes_Jail[client] = "Roubar um Carro";
			}
			case 26:
			{
				Razoes_Jail[client] = "Roubar um Barco";
			}
			case 27:
			{
				Razoes_Jail[client] = "Roubar o Ronaldo";
			}
			case 28:
			{
				Razoes_Jail[client] = "Ser Pai do Zorlak";
			}
			case 29:
			{
				Razoes_Jail[client] = "Violar Milfs";
			}
			case 30:
			{
				Razoes_Jail[client] = "Ver Porn";
			}
			case 31:
			{
				Razoes_Jail[client] = "Mijar na Cama";
			}
			case 32:
			{
				Razoes_Jail[client] = "Não saber contar";
			}
			case 33:
			{
				Razoes_Jail[client] = "Ir as Putas e Não Pagar";
			}
			case 34:
			{
				Razoes_Jail[client] = "Apanhar Sida";
			}
			case 35:
			{
				Razoes_Jail[client] = "Ter Covid";
			}
			case 36:
			{
				Razoes_Jail[client] = "Beber Leite";
			}
			case 37:
			{
				Razoes_Jail[client] = "Beber Esperma";
			}
			case 38:
			{
				Razoes_Jail[client] = "Fazer Anal";
			}
			case 39:
			{
				Razoes_Jail[client] = "Fazer Garganta Funda";
			}
			case 40:
			{
				Razoes_Jail[client] = "Fazer Espanholada";
			}
			case 41:
			{
				Razoes_Jail[client] = "Comer Iogorte";
			}
			case 42:
			{
				Razoes_Jail[client] = "Comer Peixe";
			}
			case 43:
			{
				Razoes_Jail[client] = "Comer Carne";
			}
			case 44:
			{
				Razoes_Jail[client] = "Ir a Escola";
			}
			case 45:
			{
				Razoes_Jail[client] = "Ser do Benfica";
			}
			case 46:
			{
				Razoes_Jail[client] = "Ser do Porto";
			}
			case 47:
			{
				Razoes_Jail[client] = "Ser do Sporting";
			}
			case 48:
			{
				Razoes_Jail[client] = "Trafico de Droga";
			}
			case 49:
			{
				Razoes_Jail[client] = "Violar Mulheres";
			}
			case 50:
			{
				Razoes_Jail[client] = "Violar Homens";
			}
			case 51:
			{
				Razoes_Jail[client] = "Matar a Amante";
			}
			case 52:
			{
				Razoes_Jail[client] = "Ser apanhado a foder";
			}
			case 53:
			{
				Razoes_Jail[client] = "Ser apanhado com Amante";
			}
			case 54:
			{
				Razoes_Jail[client] = "Trafico de Bebes";
			}
			case 55:
			{
				Razoes_Jail[client] = "Trafico de Idosos";
			}
			case 56:
			{
				Razoes_Jail[client] = "Gozar com um Idoso";
			}
			case 57:
			{
				Razoes_Jail[client] = "Bater a um Idoso";
			}
			case 58:
			{
				Razoes_Jail[client] = "Violar uma Idosa de 90 anos";
			}
			case 59:
			{
				Razoes_Jail[client] = "Violar uma Idosa de 101 anos";
			}
			case 60:
			{
				Razoes_Jail[client] = "Usar Viagre";
			}
			case 61:
			{
				Razoes_Jail[client] = "Usar Preservativo";
			}
			case 62:
			{
				Razoes_Jail[client] = "Meter Gasóleo no Carro";
			}
			case 63:
			{
				Razoes_Jail[client] = "Meter Gasolina no Carro";
			}
			case 64:
			{
				Razoes_Jail[client] = "Ir as compras";
			}
			case 65:
			{
				Razoes_Jail[client] = "Ir cagar";
			}
			case 66:
			{
				Razoes_Jail[client] = "Ir Mijar";
			}
			case 67:
			{
				Razoes_Jail[client] = "Roubar ChupaChupas";
			}
			case 68:
			{
				Razoes_Jail[client] = "Fazer GangBang";
			}
			case 69:
			{
				Razoes_Jail[client] = "Fazer Orgia";
			}
			case 70:
			{
				Razoes_Jail[client] = "Bater a punheta na igreja";
			}
			case 71:
			{
				Razoes_Jail[client] = "Bater a punheta na esquadra";
			}
			case 72:
			{
				Razoes_Jail[client] = "Foder um Padre";
			}
			case 73:
			{
				Razoes_Jail[client] = "Roubar um Padre";
			}
			case 74:
			{
				Razoes_Jail[client] = "Violar um Bispo";
			}
			case 75:
			{
				Razoes_Jail[client] = "Raptar o PAPA";
			}
			case 76:
			{
				Razoes_Jail[client] = "Ser Primo do Socrates";
			}
			case 77:
			{
				Razoes_Jail[client] = "Não ter Pentelhos";
			}
			case 78:
			{
				Razoes_Jail[client] = "Ser Picha Mole";
			}
			case 79:
			{
				Razoes_Jail[client] = "Matar o seu Gato";
			}
			case 80:
			{
				Razoes_Jail[client] = "Matar o seu Cao";
			}
			case 81:
			{
				Razoes_Jail[client] = "Não querer foder com a mulher";
			}
			case 82:
			{
				Razoes_Jail[client] = "Não comprar VIP na Darkness-CM";
			}
			case 83:
			{
				Razoes_Jail[client] = "Não pagar os Impostos";
			}
			case 84:
			{
				Razoes_Jail[client] = "Trafico de Armas";
			}
			case 85:
			{
				
				Razoes_Jail[client] = "Bater na Visinha";
			}
			case 86:
			{
				Razoes_Jail[client] = "Fugir do hospital do tolos";
			}
			case 87:
			{
				Razoes_Jail[client] = "Ser Burro";
			}
			case 88:
			{
				Razoes_Jail[client] = "Matar 500 Pessoas";
			}
			case 89:
			{
				Razoes_Jail[client] = "Fazer 69";
			}
			case 90:
			{
				Razoes_Jail[client] = "Mentir ao Juiz";
			}
			case 91:
			{
				Razoes_Jail[client] = "Vender Produtos Fora da Validade";
			}
			case 92:
			{
				Razoes_Jail[client] = "Vender Produtos Avariados";
			}
			case 93:
			{
				Razoes_Jail[client] = "Envenenar a Familia";
			}
			case 94:
			{
				Razoes_Jail[client] = "Usar DeepWeb";
			}
			case 95:
			{
				Razoes_Jail[client] = "Traficar Orgãos";
			}
			case 96:
			{
				Razoes_Jail[client] = "Arrancar o Penis ao AVO";
			}
			case 97:
			{
				Razoes_Jail[client] = "Arrancar o Penis ao TIO";
			}
			case 98:
			{
				Razoes_Jail[client] = "Deixar Noiva no Altar";
			}
			case 99:
			{
				Razoes_Jail[client] = "Roubar o Padeiro";
			}
			case 100:
			{
				Razoes_Jail[client] = "Roubar o Carteiro";
			}
			case 101:
			{
				Razoes_Jail[client] = "Vender Carros Roubados";
			}
			case 102:
			{
				Razoes_Jail[client] = "Comer a Tua Prima de 4";
			}
			case 103:
			{
				Razoes_Jail[client] = "Comer Prof de MAT";
			}
			case 104:
			{
				Razoes_Jail[client] = "Comer Prof de ING";
			}
			case 105:
			{
				Razoes_Jail[client] = "Comer Prof a Diretora";
			}
			case 106:
			{
				Razoes_Jail[client] = "Comer Diana Cu Melancia";
			}
			case 107:
			{
				Razoes_Jail[client] = "Comer Mia Kalifo";
			}
			case 108:
			{
				Razoes_Jail[client] = "Comer o Justin Biber";
			}
			case 109:
			{
				Razoes_Jail[client] = "Trafico de anões";
			}
			case 110:
			{
				Razoes_Jail[client] = "Violar um Anão";
			}
			case 111:
			{
				Razoes_Jail[client] = "Ser Anão";
			}
			
		}
		//	CPrintToChat(client, "\x01| {grey}Razão de Jail\x01 |{orchid} ➠{default} Foste Preso devido a {darkred}%s", Razoes_Jail[client]);
	}
}

stock int TraceClientViewEntity(int client)
{
	float m_vecOrigin[3];
	float m_angRotation[3];
	
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	
	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;
	
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	
	if (tr != INVALID_HANDLE)
	{
		CloseHandle(tr);
	}
	
	return -1;
}

public bool TRDontHitSelf(int entity, int mask, any data)
{
	return (1 <= entity <= MaxClients) && (entity != data);
}

public Action Status_player(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			int target = TraceClientViewEntity(i);
			if (target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
			{
				int vida = GetClientHealth(target);
				int colete = GetClientArmor(target);
			
				
				PrintHintText(i, "\n<font color='#FD00EE'>Nome:</font>%N \n<font color='#32FD00'>Vida:</font>%i \n<font color='#00D3FD'>Colete:</font>%i \n<font color='#FD0000'>Objetivo de Vida:</font>\n %s", target, vida, colete, Razoes_Jail[target]);
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
} 
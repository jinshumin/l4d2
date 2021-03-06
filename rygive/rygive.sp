#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define GAMEDATA "rygive"
#define NAME_CreateSmoker "NextBotCreatePlayerBot<Smoker>"
#define NAME_CreateBoomer "NextBotCreatePlayerBot<Boomer>"
#define NAME_CreateHunter "NextBotCreatePlayerBot<Hunter>"
#define NAME_CreateSpitter "NextBotCreatePlayerBot<Spitter>"
#define NAME_CreateJockey "NextBotCreatePlayerBot<Jockey>"
#define NAME_CreateCharger "NextBotCreatePlayerBot<Charger>"
#define NAME_CreateTank "NextBotCreatePlayerBot<Tank>"
#define NAME_InfectedAttackSurvivorTeam "Infected::AttackSurvivorTeam"

StringMap g_hSteamIDs;

Handle g_hSDK_Call_RoundRespawn;
Handle g_hSDK_Call_SetHumanSpec;
Handle g_hSDK_Call_TakeOverBot;
Handle g_hSDK_Call_GoAwayFromKeyboard;
Handle g_hSDK_Call_SetObserverTarget;
Handle g_hSDK_Call_CreateSmoker;
Handle g_hSDK_Call_CreateBoomer;
Handle g_hSDK_Call_CreateHunter;
Handle g_hSDK_Call_CreateSpitter;
Handle g_hSDK_Call_CreateJockey;
Handle g_hSDK_Call_CreateCharger;
Handle g_hSDK_Call_CreateTank;
Handle g_hSDK_Call_InfectedAttackSurvivorTeam;

int g_iMeleeClassCount;
int g_iClipSize_RifleM60;
int g_iClipSize_GrenadeLauncher;
int g_iFunction[MAXPLAYERS + 1];
int g_iCurrentPage[MAXPLAYERS + 1];

float g_fSpeedUp[MAXPLAYERS + 1] = 1.0;

bool g_bDebug;
bool g_bWeaponHandling;

char g_sMeleeClass[16][32];
char g_sItemName[MAXPLAYERS + 1][64];

static const char g_sMeleeModels[][] =
{
	"models/weapons/melee/v_bat.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/v_cricket_bat.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/v_crowbar.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/v_electric_guitar.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/weapons/melee/v_fireaxe.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/v_frying_pan.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/v_golfclub.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/v_katana.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/v_machete.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/v_tonfa.mdl",
	"models/weapons/melee/w_tonfa.mdl",
	"models/weapons/melee/v_riotshield.mdl",
	"models/weapons/melee/w_riotshield.mdl",
	"models/weapons/melee/v_pitchfork.mdl",
	"models/weapons/melee/w_pitchfork.mdl",
	"models/weapons/melee/v_shovel.mdl",
	"models/weapons/melee/w_shovel.mdl"
};

static const char g_sSpecialsInfectedModels[][] =
{
	"models/infected/smoker.mdl",
	"models/infected/boomer.mdl",
	"models/infected/hunter.mdl",
	"models/infected/spitter.mdl",
	"models/infected/jockey.mdl",
	"models/infected/charger.mdl",
	"models/infected/hulk.mdl",
	"models/infected/witch.mdl",
	"models/infected/witch_bride.mdl"
};

static const char g_sUncommonInfectedModels[][] =
{
	"models/infected/common_male_riot.mdl",
	"models/infected/common_male_ceda.mdl",
	"models/infected/common_male_clown.mdl",
	"models/infected/common_male_mud.mdl",
	"models/infected/common_male_roadcrew.mdl",
	"models/infected/common_male_jimmy.mdl",
	"models/infected/common_male_fallen_survivor.mdl",
};

static const char g_sMeleeName[][] =
{
	"knife",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"baseball_bat",
	"katana",
	"machete",
	"tonfa",
	"riot_shield",
	"pitchfork",
	"shovel"
};

static const char g_sMeleeTrans[][] =
{
	"??????",
	"??????",
	"??????",
	"??????",
	"??????",
	"?????????",
	"???????????????",
	"?????????",
	"?????????",
	"??????",
	"??????",
	"??????",
	"??????",
	"??????"
};

enum L4D2WeaponType 
{
	L4D2WeaponType_Unknown = 0,
	L4D2WeaponType_Pistol,
	L4D2WeaponType_Magnum,
	L4D2WeaponType_Rifle,
	L4D2WeaponType_RifleAk47,
	L4D2WeaponType_RifleDesert,
	L4D2WeaponType_RifleM60,
	L4D2WeaponType_RifleSg552,
	L4D2WeaponType_HuntingRifle,
	L4D2WeaponType_SniperAwp,
	L4D2WeaponType_SniperMilitary,
	L4D2WeaponType_SniperScout,
	L4D2WeaponType_SMG,
	L4D2WeaponType_SMGSilenced,
	L4D2WeaponType_SMGMp5,
	L4D2WeaponType_Autoshotgun,
	L4D2WeaponType_AutoshotgunSpas,
	L4D2WeaponType_Pumpshotgun,
	L4D2WeaponType_PumpshotgunChrome,
	L4D2WeaponType_Molotov,
	L4D2WeaponType_Pipebomb,
	L4D2WeaponType_FirstAid,
	L4D2WeaponType_Pills,
	L4D2WeaponType_Gascan,
	L4D2WeaponType_Oxygentank,
	L4D2WeaponType_Propanetank,
	L4D2WeaponType_Vomitjar,
	L4D2WeaponType_Adrenaline,
	L4D2WeaponType_Chainsaw,
	L4D2WeaponType_Defibrilator,
	L4D2WeaponType_GrenadeLauncher,
	L4D2WeaponType_Melee,
	L4D2WeaponType_UpgradeFire,
	L4D2WeaponType_UpgradeExplosive,
	L4D2WeaponType_BoomerClaw,
	L4D2WeaponType_ChargerClaw,
	L4D2WeaponType_HunterClaw,
	L4D2WeaponType_JockeyClaw,
	L4D2WeaponType_SmokerClaw,
	L4D2WeaponType_SpitterClaw,
	L4D2WeaponType_TankClaw,
	L4D2WeaponType_Gnome
}

//l4d_info_editor
forward void OnGetWeaponsInfo(int pThis, const char[] classname);
native void InfoEditor_GetString(int pThis, const char[] keyname, char[] dest, int destLen);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("InfoEditor_GetString");
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "WeaponHandling") == 0 )
		g_bWeaponHandling = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "WeaponHandling") == 0 )
		g_bWeaponHandling = false;
}

public Plugin myinfo =
{
	name = "Give Item Menu",
	description = "Gives Item Menu",
	author = "Ryanx, sorallll",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	LoadGameData();
	
	CreateConVar("rygive_version", "1.0.0", "rygive????????????", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	RegAdminCmd("sm_rygive", RygiveMenu, ADMFLAG_ROOT, "rygive");
	
	g_hSteamIDs = new StringMap();
}

public void OnGetWeaponsInfo(int pThis, const char[] classname)
{
	static char sResult[64];
	if(strcmp(classname, "weapon_rifle_m60") == 0)
	{
		InfoEditor_GetString(pThis, "clip_size", sResult, sizeof(sResult));
		g_iClipSize_RifleM60 = StringToInt(sResult);
	}
	else if(strcmp(classname, "weapon_grenade_launcher") == 0)
	{
		InfoEditor_GetString(pThis, "clip_size", sResult, sizeof(sResult));
		g_iClipSize_GrenadeLauncher = StringToInt(sResult);
	}
}

public void OnClientPostAdminCheck(int client)
{
	g_fSpeedUp[client] = 1.0;

	if(g_bDebug == false || IsFakeClient(client))
		return;
		
	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	bool bAllowed;
	if(!g_hSteamIDs.GetValue(sSteamID, bAllowed))
		KickClient(client, "??????????????????...");
}

public void OnMapStart()
{
	int i;
	for(i = 1; i <= MaxClients; i++)
		g_fSpeedUp[i] = 1.0;

	int iLen;

	iLen = sizeof(g_sMeleeModels);
	for(i = 0; i < iLen; i++)
	{
		if(!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}

	iLen = sizeof(g_sSpecialsInfectedModels);
	for(i = 0; i < iLen; i++)
	{
		if(!IsModelPrecached(g_sSpecialsInfectedModels[i]))
			PrecacheModel(g_sSpecialsInfectedModels[i], true);
	}
	
	iLen = sizeof(g_sUncommonInfectedModels);
	for(i = 0; i < iLen; i++)
	{
		if(!IsModelPrecached(g_sUncommonInfectedModels[i]))
			PrecacheModel(g_sUncommonInfectedModels[i], true);
	}
	
	iLen = sizeof(g_sMeleeName);
	char sBuffer[32];
	for(i = 0; i < iLen; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "scripts/melee/%s.txt", g_sMeleeName[i]);
		if(!IsGenericPrecached(sBuffer))
			PrecacheGeneric(sBuffer, true);
	}

	GetMeleeClasses();
}

stock void GetMeleeClasses()
{
	g_iMeleeClassCount = 0;
	
	int i;
	for(i = 0; i < 16; i++)
		g_sMeleeClass[i][0] = 0;
	
	int iMeleeStringTable = FindStringTable("MeleeWeapons");
	int iCount = GetStringTableNumStrings(iMeleeStringTable);
	
	char sMeleeClass[16][32];
	for(i = 0; i < iCount; i++)
	{
		ReadStringTable(iMeleeStringTable, i, sMeleeClass[i], sizeof(sMeleeClass[]));
		if(IsVaidMelee(sMeleeClass[i]))
			strcopy(g_sMeleeClass[g_iMeleeClassCount++], sizeof(g_sMeleeClass[]), sMeleeClass[i]);
	}
}

stock bool IsVaidMelee(const char[] sWeapon)
{
	bool bIsVaid = false;
	int iEntity = CreateEntityByName("weapon_melee");
	DispatchKeyValue(iEntity, "melee_script_name", sWeapon);
	DispatchSpawn(iEntity);

	char sModelName[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	if(StrContains(sModelName, "hunter", false) == -1)
		bIsVaid  = true;

	RemoveEdict(iEntity);
	return bIsVaid;
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if((client == 0 || !IsFakeClient(client)) && !RealPlayerExist(client))
	{
		g_hSteamIDs.Clear();
		g_bDebug = false;
	}
}

bool RealPlayerExist(int iExclude = 0)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client != iExclude && IsClientConnected(client) && !IsFakeClient(client))
			return true;
	}
	return false;
}

public Action RygiveMenu(int client, int args)
{
	if(client && IsClientInGame(client))
		Rygive(client);

	return Plugin_Handled;
}

public Action Rygive(int client)
{
	Menu menu = new Menu(MenuHandler_Rygive);
	menu.SetTitle("???????????????");
	menu.AddItem("0", "??????");
	menu.AddItem("1", "??????");
	menu.AddItem("2", "??????");
	menu.AddItem("3", "??????");
	menu.AddItem("4", "????????????");
	if(g_bDebug == false)
		menu.AddItem("5", "??????????????????");
	else
		menu.AddItem("5", "??????????????????");
	if(g_bWeaponHandling)
		menu.AddItem("6", "???????????????(??????/?????????)");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler_Rygive(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					Action_Weapons(client);
				case 1:
					Action_Items(client, 0);
				case 2:
					Action_Infected(client, 0);
				case 3:
					Action_Othoer(client, 0);
				case 4:
					Action_TeamSwitch(client, 0);
				case 5:
					Action_DebugMode(client);
				case 6:
					Action_HandlingAPI(client, 0);
			}
		}
		case MenuAction_End:
			delete menu;
	}
}

void Action_Weapons(int client)
{
	Menu menu = new Menu(MenuHandler_Weapons);
	menu.SetTitle("??????");
	menu.AddItem("0", "??????");
	menu.AddItem("1", "??????");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			g_iCurrentPage[client] = menu.Selection;
			switch(param2)
			{
				case 0:
					Gun_Menu(client, 0);
				case 1:
					Melee_Menu(client, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

void Gun_Menu(int client, int index)
{
	Menu menu = new Menu(MenuHandler_Gun);
	menu.SetTitle("??????");
	menu.AddItem("pistol", "??????");
	menu.AddItem("pistol_magnum", "?????????");
	menu.AddItem("chainsaw", "??????");
	menu.AddItem("smg", "UZI??????");
	menu.AddItem("smg_mp5", "MP5");
	menu.AddItem("smg_silenced", "MAC??????");
	menu.AddItem("pumpshotgun", "??????");
	menu.AddItem("shotgun_chrome", "??????");
	menu.AddItem("rifle", "M16??????");
	menu.AddItem("rifle_desert", "????????????");
	menu.AddItem("rifle_ak47", "AK47");
	menu.AddItem("rifle_sg552", "SG552");
	menu.AddItem("autoshotgun", "????????????");
	menu.AddItem("shotgun_spas", "????????????");
	menu.AddItem("hunting_rifle", "??????");
	menu.AddItem("sniper_military", "??????");
	menu.AddItem("sniper_scout", "??????");
	menu.AddItem("sniper_awp", "AWP");
	menu.AddItem("rifle_m60", "M60");
	menu.AddItem("grenade_launcher", "???????????????");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_Gun(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iFunction[client] = 1;
				g_iCurrentPage[client] = menu.Selection;
				FormatEx(g_sItemName[client], sizeof(g_sItemName), "give %s", sItem);
				ListAliveSurvivor(client);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Weapons(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

void Melee_Menu(int client, int index)
{
	Menu menu = new Menu(MenuHandler_Melee);
	menu.SetTitle("??????");
	for(int i; i < g_iMeleeClassCount; i++)
	{
		int iTrans = GetMeleeTrans(g_sMeleeClass[i]);
		if(iTrans != -1)
			menu.AddItem(g_sMeleeClass[i], g_sMeleeTrans[iTrans]);
		else
			menu.AddItem(g_sMeleeClass[i], g_sMeleeClass[i]); //????????????????????????????????????????????????
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

stock int GetMeleeTrans(const char[] sMeleeName)
{
	for(int i; i < sizeof(g_sMeleeName); i++)
	{
		if(strcmp(g_sMeleeName[i], sMeleeName) == 0)
			return i;
	}
	return -1;
}

public int MenuHandler_Melee(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iFunction[client] = 2;
				g_iCurrentPage[client] = menu.Selection;
				FormatEx(g_sItemName[client], sizeof(g_sItemName), "give %s", sItem);
				ListAliveSurvivor(client);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Weapons(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

void Action_Items(int client, int index)
{
	Menu menu = new Menu(MenuHandler_Items);
	menu.SetTitle("??????");
	menu.AddItem("health", "?????????");
	menu.AddItem("molotov", "?????????");
	menu.AddItem("pipe_bomb", "????????????");
	menu.AddItem("vomitjar", "?????????");
	menu.AddItem("first_aid_kit", "?????????");
	menu.AddItem("defibrillator", "?????????");
	menu.AddItem("upgradepack_incendiary", "???????????????");
	menu.AddItem("upgradepack_explosive", "???????????????");
	menu.AddItem("adrenaline", "????????????");
	menu.AddItem("pain_pills", "?????????");
	menu.AddItem("gascan", "?????????");
	menu.AddItem("propanetank", "?????????");
	menu.AddItem("oxygentank", "?????????");
	menu.AddItem("fireworkcrate", "?????????");
	menu.AddItem("gnome", "????????????");
	menu.AddItem("ammo", "????????????");
	menu.AddItem("incendiary_ammo", "????????????");
	menu.AddItem("explosive_ammo", "????????????");
	menu.AddItem("laser_sight", "???????????????");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_Items(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iFunction[client] = 3;
				g_iCurrentPage[client] = menu.Selection;

				if(param2 < 16)
					FormatEx(g_sItemName[client], sizeof(g_sItemName), "give %s", sItem);
				else
					FormatEx(g_sItemName[client], sizeof(g_sItemName), "upgrade_add %s", sItem);
				
				ListAliveSurvivor(client);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;	
	}
}

void Action_Infected(int client, int index)
{
	Menu menu = new Menu(MenuHandler_Infected);
	menu.SetTitle("??????");
	menu.AddItem("Smoker", "Smoker");
	menu.AddItem("Boomer", "Boomer");
	menu.AddItem("Hunter", "Hunter");
	menu.AddItem("Jockey", "Jockey");
	menu.AddItem("Spitter", "Spitter");
	menu.AddItem("Charger", "Charger");
	menu.AddItem("Tank", "Tank");
	menu.AddItem("Witch", "Witch");
	menu.AddItem("Witch_Bride", "Bride Witch");
	menu.AddItem("Common", "Common");
	menu.AddItem("0", "Riot");
	menu.AddItem("1", "Ceda");
	menu.AddItem("2", "Clown");
	menu.AddItem("3", "Mudmen");
	menu.AddItem("4", "Roadworker");
	menu.AddItem("5", "Jimmie Gibbs");
	menu.AddItem("6", "Fallen Survivor");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_Infected(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[128];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				int iKick;
				if(GetClientCount(false) >= (MaxClients - 1))
				{
					PrintToChat(client, "????????????????????????????????????...");
					iKick = KickDeadInfectedBots(client);
				}
	
				if(iKick <= 0)
					CreateInfectedWithParams(client, sItem, 0, 5);
				else
				{
					DataPack datapack = new DataPack();
					datapack.WriteCell(client);
					datapack.WriteString(sItem);
					RequestFrame(OnNextFrame_CreateInfected, datapack);
				}
			}
			Action_Infected(client, menu.Selection);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

public void OnNextFrame_CreateInfected(DataPack datapack)
{
	datapack.Reset();
	int client = datapack.ReadCell();
	char sZombie[128];
	datapack.ReadString(sZombie, sizeof(sZombie));
	delete datapack;
	
	CreateInfectedWithParams(client, sZombie, 0, 5);
}

//https://github.com/ProdigySim/DirectInfectedSpawn
int CreateInfectedWithParams(int client, const char[] sZombie, int iMode=0, int iNumber=1)
{
	float vPos[3];
	float vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);
	if(iMode <= 0)
	{
		GetClientEyePosition(client, vPos);
		GetClientEyeAngles(client, vAng);
		TR_TraceRayFilter(vPos, vAng, MASK_OPAQUE, RayType_Infinite, TraceRayDontHitPlayers, client);
		if(TR_DidHit())
			TR_GetEndPosition(vPos);
	}
	
	vAng[0] = 0.0;
	vAng[2] = 0.0;

	int infected;
	for(int i;i < iNumber;i++)
	{
		infected = CreateInfected(sZombie, vPos, vAng);
		if(IsValidEntity(infected))
			break;
	}

	return infected;
}

bool TraceRayDontHitPlayers(int entity, int contentsMask, any data)
{
	if(IsValidClient(data))
		return false;

	return true;
}

int CreateInfected(const char[] sZombie, const float[3] vPos, const float[3] vAng)
{
	int iBot = -1;
	if(strcmp(sZombie, "witch", false) == 0 || strcmp(sZombie, "witch_bride", false) == 0)
	{
		int witch = CreateEntityByName("witch");
		DispatchSpawn(witch);
		ActivateEntity(witch);
		TeleportEntity(witch, vPos, vAng, NULL_VECTOR);

		if(strcmp(sZombie, "witch_bride", false) == 0)
			SetEntityModel(witch, g_sSpecialsInfectedModels[8]);

		return witch;
	}
	else if(strcmp(sZombie, "smoker", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateSmoker, "Smoker");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[0]);
	}
	else if(strcmp(sZombie, "boomer", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateBoomer, "Boomer");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[1]);
	}
	else if(strcmp(sZombie, "hunter", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateHunter, "Hunter");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[2]);
	}
	else if(strcmp(sZombie, "spitter", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateSpitter, "Spitter");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[3]);
	}
	else if(strcmp(sZombie, "jockey", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateJockey, "Jockey");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[4]);
	}
	else if(strcmp(sZombie, "charger", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateCharger, "Charger");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[5]);
	}
	else if(strcmp(sZombie, "tank", false) == 0)
	{
		iBot = SDKCall(g_hSDK_Call_CreateTank, "Tank");
		if(IsValidClient(iBot))
			SetEntityModel(iBot, g_sSpecialsInfectedModels[6]);
	}
	else
	{
		int infected = CreateEntityByName("infected");
		if(strcmp(sZombie, "common", false) != 0)
			SetEntityModel(infected, g_sUncommonInfectedModels[StringToInt(sZombie)]);
		DispatchSpawn(infected);
		ActivateEntity(infected);
		TeleportEntity(infected, vPos, vAng, NULL_VECTOR);
		CreateTimer(0.4, Timer_Chase, infected);
	
		return infected;
	}
	
	if(IsValidClient(iBot))
	{
		ChangeClientTeam(iBot, 3);
		SetEntProp(iBot, Prop_Send, "m_usSolidFlags", 16);
		SetEntProp(iBot, Prop_Send, "movetype", 2);
		SetEntProp(iBot, Prop_Send, "deadflag", 0);
		SetEntProp(iBot, Prop_Send, "m_lifeState", 0);
		//SetEntProp(iBot, Prop_Send, "m_fFlags", 129);
		SetEntProp(iBot, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(iBot, Prop_Send, "m_iPlayerState", 0);
		SetEntProp(iBot, Prop_Send, "m_zombieState", 0);
		DispatchSpawn(iBot);
		ActivateEntity(iBot);
		
		DataPack datapack = new DataPack();
		datapack.WriteFloat(vPos[0]);
		datapack.WriteFloat(vPos[1]);
		datapack.WriteFloat(vPos[2]);
		datapack.WriteFloat(vAng[1]);
		datapack.WriteCell(iBot);
		RequestFrame(OnNextFrame_SetPos, datapack);
	}
	
	return iBot;
}

Action Timer_Chase(Handle timer, int infected)
{
	if(!IsValidEntity(infected))
		return;

	char class[64];
	GetEntityClassname(infected, class, sizeof(class));
	if(strcmp(class, "infected", false) != 0)
		return;

	SDKCall(g_hSDK_Call_InfectedAttackSurvivorTeam, infected);
}

public void OnNextFrame_SetPos(DataPack datapack)
{
	datapack.Reset();
	float vPos[3], vAng[3];
	vPos[0] = datapack.ReadFloat();
	vPos[1] = datapack.ReadFloat();
	vPos[2] = datapack.ReadFloat();
	vAng[1] = datapack.ReadFloat();
	int iBot = datapack.ReadCell();
	delete datapack;

	TeleportEntity(iBot, vPos, vAng, NULL_VECTOR);
}

int KickDeadInfectedBots(int client)
{
	int iKickedBots;
	for(int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++)
	{
		if(!IsValidClient(iLoopClient))
			continue;

		if(!IsInfected(iLoopClient) || !IsFakeClient(iLoopClient) || IsPlayerAlive(iLoopClient))
			continue;
	
		KickClient(iLoopClient);
		iKickedBots++;
	}

	if(iKickedBots > 0)
		PrintToChat(client, "Kicked %i bots.", iKickedBots);

	return iKickedBots;
}

bool IsInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

void Action_Othoer(int client, int index)
{
	Menu menu = new Menu(MenuHandler_Othoer);
	menu.SetTitle("??????");
	menu.AddItem("0", "??????");
	menu.AddItem("1", "??????");
	menu.AddItem("2", "??????");
	menu.AddItem("3", "??????");
	menu.AddItem("4", "??????");
	menu.AddItem("5", "????????????");
	menu.AddItem("6", "????????????Bot");
	menu.AddItem("7", "??????????????????");
	menu.AddItem("8", "??????????????????");
	menu.AddItem("9", "???????????????????????????");
	menu.AddItem("10", "???????????????????????????");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_Othoer(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				switch(param2)
				{
					case 0:
						IncapSurvivor(client, 0);
					case 1:
						StripWeapon(client, 0);
					case 2:
						RespawnSurvivor(client, 0);
					case 3:
						TeleportPlayer(client, 0);
					case 4:
						FriendlyFire(client);
					case 5:
						ForcePanicEvent(client);
					case 6:
						KickAllSurvivorBot(client);
					case 7:
						SlayAllInfected(/*client*/);
					case 8:
						SlayAllSurvivor(/*client*/);
					case 9:
						WarpAllSurvivorsToStartArea(/*client*/);
					case 10:
						WarpAllSurvivorsToCheckpoint(/*client*/);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

void IncapSurvivor(int client, int index)
{
	char sUserId[16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_IncapSurvivor);
	menu.SetTitle("????????????");
	menu.AddItem("allplayer", "??????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsIncapacitated(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserId, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_IncapSurvivor(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				if(strcmp(sItem, "allplayer") == 0)
				{
					for(int i = 1; i <= MaxClients; i++)
						IncapCheck(i);
						
					Action_Othoer(client, 0);
				}
				else
				{
					int iTarget = GetClientOfUserId(StringToInt(sItem));
					if(iTarget && IsClientInGame(iTarget))
						IncapCheck(iTarget);
						
					IncapSurvivor(client, menu.Selection);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Othoer(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
}

stock bool IsIncapacitated(int client) 
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0;
}

void IncapCheck(int client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsIncapacitated(client))
	{
		if(FindConVar("survivor_max_incapacitated_count").IntValue == GetEntProp(client, Prop_Send, "m_currentReviveCount"))
		{
			SetEntProp(client, Prop_Send, "m_currentReviveCount", FindConVar("survivor_max_incapacitated_count").IntValue - 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
		IncapPlayer(client);
	}
}

stock void IncapPlayer(int client) 
{
	float vPos[3];
	char sUser[MAX_NAME_LENGTH];
	GetClientAbsOrigin(client, vPos);
	FormatEx(sUser, sizeof(sUser), "hurtme%d", client);
	int iEntity = CreateEntityByName("point_hurt");
	if(iEntity != -1)
	{
		SetEntityHealth(client, 1);
		DispatchKeyValue(iEntity, "Damage", "6000");
		DispatchKeyValue(iEntity, "DamageType", "128");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iEntity, "DamageTarget", sUser);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEntity, "Hurt");
		RemoveEntity(iEntity);
	}
}

void StripWeapon(int client, int index)
{
	char sUserId[16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_StripWeapon);
	menu.SetTitle("????????????");
	menu.AddItem("allplayer", "??????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserId, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_StripWeapon(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				if(strcmp(sItem, "allplayer") == 0)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							DeletePlayerSlotAll(i);
					}
					Action_Othoer(client, 0);
				}
				else
				{
					int iTarget = GetClientOfUserId(StringToInt(sItem));
					if(iTarget && IsClientInGame(iTarget))
					{
						g_iCurrentPage[client] = menu.Selection;
						SlotSlect(client, iTarget);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Othoer(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
}

void SlotSlect(int client, int target)
{
	char sUserId[3][16];
	char sUserInfo[32];
	char sClsaaname[32];
	Menu menu = new Menu(MenuHandler_SlotSlect);
	menu.SetTitle("????????????");
	FormatEx(sUserId[0], sizeof(sUserId[]), "%d", GetClientUserId(target));
	strcopy(sUserId[1], sizeof(sUserId[]), "allslot");
	ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
	menu.AddItem(sUserInfo, "????????????");
	for(int i; i < 5; i++)
	{
		int iWeapon = GetPlayerWeaponSlot(target, i);
		if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		{
			FormatEx(sUserId[1], sizeof(sUserId[]), "%d", i);
			ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
			GetEntityClassname(iWeapon, sClsaaname, sizeof(sClsaaname));
			menu.AddItem(sUserInfo, sClsaaname[7]);
		}	
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SlotSlect(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				char sInfo[2][16];
				ExplodeString(sItem, "|", sInfo, 2, 16);
				int iTarget = GetClientOfUserId(StringToInt(sInfo[0]));
				if(iTarget && IsClientInGame(iTarget))
				{
					if(strcmp(sInfo[1], "allslot") == 0)
					{
						DeletePlayerSlotAll(iTarget);
						StripWeapon(client, g_iCurrentPage[client]);
					}
					else
					{
						DeletePlayerSlotX(iTarget, StringToInt(sInfo[1]));
						SlotSlect(client, iTarget);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				StripWeapon(client, g_iCurrentPage[client]);
		}
		case MenuAction_End:
			delete menu;
	}
}

stock void DeletePlayerSlot(int client, int weapon)
{		
	if(RemovePlayerItem(client, weapon))
		RemoveEntity(weapon);
}

stock void DeletePlayerSlotX(int client, int iSlot)
{
	iSlot = GetPlayerWeaponSlot(client, iSlot);
	if(iSlot > 0)
	{
		if(RemovePlayerItem(client, iSlot))
			RemoveEntity(iSlot);
	}
}

stock void DeletePlayerSlotAll(int client)
{
	int iSlot;
	for(int i; i < 5; i++)
	{
		iSlot = GetPlayerWeaponSlot(client, i);
		if(iSlot > 0)
			DeletePlayerSlot(client, iSlot);
	}
}

void RespawnSurvivor(int client, int index)
{
	char sUserId[16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_RespawnSurvivor);
	menu.SetTitle("????????????");
	menu.AddItem("alldead", "??????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserId, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_RespawnSurvivor(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				if(strcmp(sItem, "alldead") == 0)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
						{
							SDKCall(g_hSDK_Call_RoundRespawn, i);
							TeleportToSurvivor(i);
						}
					}
					Action_Othoer(client, 0);
				}
				else
				{
					int iTarget = GetClientOfUserId(StringToInt(sItem));
					if(iTarget && IsClientInGame(iTarget))
					{
						SDKCall(g_hSDK_Call_RoundRespawn, iTarget);
						TeleportToSurvivor(iTarget);
					}
					RespawnSurvivor(client, menu.Selection);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Othoer(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
}

void TeleportToSurvivor(int client)
{
	int iTarget = GetTeleportTarget(client);
	if(iTarget != -1)
	{
		float vPos[3];
		GetClientAbsOrigin(iTarget, vPos);
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}
}

int GetTeleportTarget(int client)
{
	int iNormal, iIncap, iHanging;
	int[] iNormalSurvivors = new int[MaxClients];
	int[] iIncapSurvivors = new int[MaxClients];
	int[] iHangingSurvivors = new int[MaxClients];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(GetEntProp(i, Prop_Send, "m_isIncapacitated") > 0)
			{
				if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0)
					iHangingSurvivors[iHanging++] = i;
				else
					iIncapSurvivors[iIncap++] = i;
			}
			else
				iNormalSurvivors[iNormal++] = i;
		}
	}
	return (iNormal == 0) ? (iIncap == 0 ? (iHanging == 0 ? -1 : iHangingSurvivors[GetRandomInt(0, iHanging - 1)]) : iIncapSurvivors[GetRandomInt(0, iIncap - 1)]) :iNormalSurvivors[GetRandomInt(0, iNormal - 1)];
}

void FriendlyFire(int client)
{
	Menu menu = new Menu(MenuHandler_FriendlyFire);
	menu.SetTitle("??????");
	menu.AddItem("999", "????????????");
	menu.AddItem("0.0", "0.0(??????)");
	menu.AddItem("0.1", "0.1(??????)");
	menu.AddItem("0.2", "0.2");
	menu.AddItem("0.3", "0.3(??????)");
	menu.AddItem("0.4", "0.4");
	menu.AddItem("0.5", "0.5(??????)");
	menu.AddItem("0.6", "0.6");
	menu.AddItem("0.7", "0.7");
	menu.AddItem("0.8", "0.8");
	menu.AddItem("0.9", "0.9");
	menu.AddItem("1.0", "1.0");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_FriendlyFire(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				switch(param2)
				{
					case 0:
					{
						FindConVar("survivor_friendly_fire_factor_easy").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_normal").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_hard").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_expert").RestoreDefault();
					}
					default:
					{
						float percent = StringToFloat(sItem);
						FindConVar("survivor_friendly_fire_factor_easy").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_normal").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_hard").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_expert").SetFloat(percent);
					}
				}
				Action_Othoer(client, 0);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Othoer(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
}

void TeleportPlayer(int client, int index)
{
	char sUserId[16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_TeleportPlayer);
	menu.SetTitle("?????????");
	menu.AddItem("allsurvivor", "???????????????");
	menu.AddItem("allinfected", "???????????????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserId, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_TeleportPlayer(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iCurrentPage[client] = menu.Selection;
				TeleportTarget(client, sItem);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_Othoer(client, 0);
		}
		case MenuAction_End:
			delete menu;
	}
}

void TeleportTarget(int client, const char[] sTarget)
{
	char sUserId[2][16];
	char sUserInfo[32];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_TeleportTarget);
	menu.SetTitle("???????????????");
	strcopy(sUserId[0], sizeof(sUserId[]), sTarget);
	strcopy(sUserId[1], sizeof(sUserId[]), "crh");
	ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
	menu.AddItem(sUserInfo, "???????????????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(sUserId[1], sizeof(sUserId[]), "%d", GetClientUserId(i));
			ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserInfo, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_TeleportTarget(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				char sInfo[2][16];
				bool bAllowTeleport;
				float vOrigin[3];
				ExplodeString(sItem, "|", sInfo, 2, 16);
				if(strcmp(sInfo[1], "crh") == 0)
					bAllowTeleport = GetSpawnEndPoint(client, vOrigin);
				else
				{
					int iTarget = GetClientOfUserId(StringToInt(sInfo[1]));
					if(iTarget && IsClientInGame(iTarget))
					{
						GetClientAbsOrigin(iTarget, vOrigin);
						bAllowTeleport = true;
					}
				}

				if(bAllowTeleport == true)
				{
					if(strcmp(sInfo[0], "allsurvivor") == 0)
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							{
								TeleportCheck(i);
								TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
					else if(strcmp(sInfo[0], "allinfected") == 0)
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
								TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else
					{
						int iVictim = GetClientOfUserId(StringToInt(sInfo[0]));
						if(iVictim && IsClientInGame(iVictim))
						{
							TeleportCheck(iVictim);
							TeleportEntity(iVictim, vOrigin, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
				else if(strcmp(sInfo[1], "crh") == 0)
					PrintToChat(client, "???????????????????????????!???????????????.");
	
				TeleportPlayer(client, g_iCurrentPage[client]);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				TeleportPlayer(client, g_iCurrentPage[client]);
		}
		case MenuAction_End:
			delete menu;
	}
}

//https://forums.alliedmods.net/showthread.php?p=2693455
bool GetSpawnEndPoint(int client, float vSpawnVec[3])
{
	float vEnd[3], vEye[3];
	if(GetDirectionEndPoint(client, vEnd))
	{
		GetClientEyePosition(client, vEye);
		ScaleVectorDirection(vEye, vEnd, 0.1); // to allow collision to be happen
		if(GetNonCollideEndPoint(client, vEnd, vSpawnVec))
			return true;
	}

	return false;
}

void ScaleVectorDirection(float vStart[3], float vEnd[3], float fMultiple)
{
    float dir[3];
    SubtractVectors(vEnd, vStart, dir);
    ScaleVector(dir, fMultiple);
    AddVectors(vEnd, dir, vEnd);
}

stock bool GetDirectionEndPoint(int client, float vEndPos[3])
{
	float vDir[3], vPos[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vDir);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID, RayType_Infinite, bTraceEntityFilterPlayer);
	if(hTrace != null)
	{
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(vEndPos, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

stock bool GetNonCollideEndPoint(int client, float vEnd[3], float vEndNonCol[3])
{
	float vMin[3], vMax[3], vStart[3];
	GetClientEyePosition(client, vStart);
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);
	vStart[2] += 20.0; // if nearby area is irregular
	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, vMin, vMax, MASK_PLAYERSOLID, bTraceEntityFilterPlayer);
	if(hTrace != null)
	{
		if(TR_DidHit(hTrace))
		{
			TR_GetEndPosition(vEndNonCol, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

public bool bTraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

stock void TeleportCheck(int client)
{
	if(GetClientTeam(client) != 2)
		return;
	
	if(IsHanging(client))
		L4D2_ReviveFromIncap(client);
	else
		ChargerCheck(client);
}

//https://github.com/LuxLuma/Scuffle
stock void ChargerCheck(int client)
{
	static const char attackTypes[][] = 
	{
		"m_pummelAttacker",
		"m_carryAttacker" 
	};
	for(int i; i < sizeof(attackTypes); i++)
	{
		if(HasEntProp(client, Prop_Send, attackTypes[i]))
		{
			int attackerId = GetEntPropEnt(client, Prop_Send, attackTypes[i]);
			if(attackerId > 0)
			{
				L4D2_Stagger(attackerId);
				break;
			}
		}
	}
}

stock void L4D2_Stagger(int iClient, float fPos[3]=NULL_VECTOR) 
{
    /**
    * Stagger a client (Credit to Timocop)
    *
    * @param iClient    Client to stagger
    * @param fPos       Vector to stagger
    * @return void
    */

    L4D2_RunScript("GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", GetClientUserId(iClient), RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
}

//https://forums.alliedmods.net/showpost.php?p=2681159&postcount=10
stock bool IsHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") > 0;
}

stock void L4D2_ReviveFromIncap(int client) 
{
	L4D2_RunScript("GetPlayerFromUserID(%d).ReviveFromIncap()", GetClientUserId(client));
}

stock void L4D2_RunScript(const char[] sCode, any ...) 
{
	/**
	* Run a VScript (Credit to Timocop)
	*
	* @param sCode		Magic
	* @return void
	*/

	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
			SetFailState("Could not create 'logic_script'");

		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

void ForcePanicEvent(int client)
{
	CheatCommand(client, "director_force_panic_event");
	Action_Othoer(client, 0);
}

void KickAllSurvivorBot(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			KickClient(i);
	}
	Action_Othoer(client, 0);
}

void SlayAllInfected(/*int client*/)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	//Action_Othoer(client, 7);
}

void SlayAllSurvivor(/*int client*/)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	//Action_Othoer(client, 7);
}

void WarpAllSurvivorsToStartArea()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			QuickCheat(i, "warp_to_start_area");
	}
}

void WarpAllSurvivorsToCheckpoint()
{
	int iCmdClient = GetAnyClient();
	if(iCmdClient)
		QuickCheat(iCmdClient, "warp_all_survivors_to_checkpoint");
}

stock int GetAnyClient()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			return i;
	}
	return 0;
}

stock void QuickCheat(int client, const char [] sCmd)
{
    int flags = GetCommandFlags(sCmd);
    SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s", sCmd);
    SetCommandFlags(sCmd, flags);
}

void Action_TeamSwitch(int client, int index)
{
	char sUserId[16];
	char sInfo[PLATFORM_MAX_PATH];
	Menu menu = new Menu(MenuHandler_TeamSwitch);
	menu.SetTitle("????????????");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sInfo, sizeof(sInfo), "%N", i);
			switch(GetClientTeam(i))
			{
				case 1:
				{
					if(GetBotOfIdle(i))
						Format(sInfo, sizeof(sInfo), "?????? - %s", sInfo);
					else
						Format(sInfo, sizeof(sInfo), "?????? - %s", sInfo);
				}
				
				case 2:
					Format(sInfo, sizeof(sInfo), "?????? - %s", sInfo);
					
				case 3:
					Format(sInfo, sizeof(sInfo), "?????? - %s", sInfo);
			}

			menu.AddItem(sUserId, sInfo);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_TeamSwitch(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iCurrentPage[client] = menu.Selection;

				int iTarget = GetClientOfUserId(StringToInt(sItem));
				if(iTarget && IsClientInGame(iTarget))
					SwitchPlayerTeam(client, iTarget);
				else
					PrintToChat(client, "???????????????????????????");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

static const int g_iTargetTeam[4] = {0, 1, 2, 3};
static const char g_sTargetTeam[4][] = {"??????(?????????)", "??????", "??????", "??????"};
void SwitchPlayerTeam(int client, int iTarget)
{
	char sUserId[2][16];
	char sUserInfo[32];
	Menu menu = new Menu(MenuHandler_SwitchPlayerTeam);
	menu.SetTitle("????????????");
	FormatEx(sUserId[0], sizeof(sUserId[]), "%d", GetClientUserId(iTarget));

	int iTeam;
	if(!GetBotOfIdle(iTarget))
		iTeam = GetClientTeam(iTarget);

	for(int i; i < 4; i++)
	{
		if(iTeam == i || (iTeam != 2 && i == 0))
			continue;

		IntToString(g_iTargetTeam[i], sUserId[1], sizeof(sUserId[]));
		ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
		menu.AddItem(sUserInfo, g_sTargetTeam[i]);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SwitchPlayerTeam(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				char sInfo[2][16];
				ExplodeString(sItem, "|", sInfo, 2, 16);
				int iTarget = GetClientOfUserId(StringToInt(sInfo[0]));
				if(iTarget && IsClientInGame(iTarget))
				{
					int iOnTeam;
					if(!GetBotOfIdle(iTarget))
						iOnTeam = GetClientTeam(iTarget);

					int iTargetTeam = StringToInt(sInfo[1]);
					if(iOnTeam != iTargetTeam)
					{
						switch(iTargetTeam)
						{
							case 0:
							{
								if(iOnTeam == 2)
									SDKCall(g_hSDK_Call_GoAwayFromKeyboard, iTarget);
								else
									PrintToChat(client, "?????????????????????????????????");
							}

							case 1:
							{
								if(iOnTeam == 0)
									SDKCall(g_hSDK_Call_TakeOverBot, iTarget, true);

								ChangeClientTeam(iTarget, iTargetTeam);
							}

							case 2:
								ChangeTeamToSurvivor(iTarget, iOnTeam);

							case 3:
								ChangeClientTeam(iTarget, iTargetTeam);
						}
					}
					else
						PrintToChat(client, "???????????????????????????");
						
					Action_TeamSwitch(client, g_iCurrentPage[client]);
				}
				else
					PrintToChat(client, "???????????????????????????");
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_TeamSwitch(client, g_iCurrentPage[client]);
		}
		case MenuAction_End:
			delete menu;
	}
}

void ChangeTeamToSurvivor(int client, int iTeam)
{
	if(GetEntProp(client, Prop_Send, "m_isGhost") == 1)
		SetEntProp(client, Prop_Send, "m_isGhost", 0);

	if(iTeam != 1)
		ChangeClientTeam(client, 1);

	int iBot;
	if((iBot = GetBotOfIdle(client)))
	{
		SDKCall(g_hSDK_Call_TakeOverBot, client, true);
		return;
	}
	else
		iBot = GetAnyValidAliveSurvivorBot();

	if(iBot)
	{
		SDKCall(g_hSDK_Call_SetHumanSpec, iBot, client);
		SDKCall(g_hSDK_Call_SetObserverTarget, client, iBot);
		SDKCall(g_hSDK_Call_TakeOverBot, client, true);
	}
	else
		ChangeClientTeam(client, 2);
}

int GetAnyValidAliveSurvivorBot()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidAliveSurvivorBot(i)) 
			return i;
	}
	return 0;
}

bool IsValidAliveSurvivorBot(int client)
{
	return IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsClientInKickQueue(client) && !HasIdlePlayer(client);
}

int GetBotOfIdle(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && (GetIdlePlayer(i) == client)) 
			return i;
	}
	return 0;
}

int GetIdlePlayer(int client)
{
	if(IsPlayerAlive(client))
		return HasIdlePlayer(client);

	return 0;
}

int HasIdlePlayer(int client)
{
	if(HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
	{
		client = GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));			
		if(client > 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 1)
			return client;
	}
	return 0;
}

void Action_DebugMode(int client)
{
	if(g_bDebug == true)
	{
		g_hSteamIDs.Clear();
			
		g_bDebug = false;
		ReplyToCommand(client, "?????????????????????.");
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				char sSteamID[64];
				GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
				g_hSteamIDs.SetValue(sSteamID, true, true);
			}
		}
		
		g_bDebug = true;
		ReplyToCommand(client, "?????????????????????.");
	}
	
	Rygive(client);
}

void Action_HandlingAPI(int client, int index)
{
	Menu menu = new Menu(MenuHandler_HandlingAPI);
	menu.SetTitle("??????");
	menu.AddItem("1.0", "1.0(????????????)");
	menu.AddItem("1.1", "1.1x");
	menu.AddItem("1.2", "1.2x");
	menu.AddItem("1.3", "1.3x");
	menu.AddItem("1.4", "1.4x");
	menu.AddItem("1.5", "1.5x");
	menu.AddItem("1.6", "1.6x");
	menu.AddItem("1.7", "1.7x");
	menu.AddItem("1.8", "1.8x");
	menu.AddItem("1.9", "1.9x");
	menu.AddItem("2.0", "2.0x");
	menu.AddItem("2.1", "2.1x");
	menu.AddItem("2.2", "2.2x");
	menu.AddItem("2.3", "2.3x");
	menu.AddItem("2.4", "2.4x");
	menu.AddItem("2.5", "2.5x");
	menu.AddItem("2.6", "2.6x");
	menu.AddItem("2.7", "2.7x");
	menu.AddItem("2.8", "2.8x");
	menu.AddItem("2.9", "2.9x");
	menu.AddItem("3.0", "3.0x");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

public int MenuHandler_HandlingAPI(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				g_iCurrentPage[client] = menu.Selection;
				WeaponSpeedUp(client, sItem);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

void WeaponSpeedUp(int client, const char[] sSpeedUp)
{
	char sUserId[2][16];
	char sUserInfo[32];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_WeaponSpeedUp);
	menu.SetTitle("????????????");
	strcopy(sUserId[0], sizeof(sUserId[]), sSpeedUp);
	strcopy(sUserId[1], sizeof(sUserId[]), "allplayer");
	ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
	menu.AddItem(sUserInfo, "??????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			FormatEx(sUserId[1], sizeof(sUserId[]), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "(%.1fx)%N", g_fSpeedUp[i], i);
			ImplodeStrings(sUserId, 2, "|", sUserInfo, sizeof(sUserInfo));
			menu.AddItem(sUserInfo, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_WeaponSpeedUp(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				char sInfo[2][16];
				ExplodeString(sItem, "|", sInfo, 2, 16);
				float fSpeedUp = StringToFloat(sInfo[0]);
				if(strcmp(sInfo[1], "allplayer") == 0)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i))
							g_fSpeedUp[i] = fSpeedUp;
					}
					PrintToChat(client, "\x05???????????? \x01????????????????????????????????? \x04%.1fx", fSpeedUp);
					Rygive(client);
				}
				else
				{
					int iTarget = GetClientOfUserId(StringToInt(sInfo[1]));
					if(iTarget && IsClientInGame(iTarget))
					{
						g_fSpeedUp[iTarget] = fSpeedUp;
						PrintToChat(client, "\x05%N \x01????????????????????????????????? \x04%.1fx", iTarget, fSpeedUp);
					}
					else
						PrintToChat(client, "???????????????????????????");
						
					Action_HandlingAPI(client, g_iCurrentPage[client]);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Action_HandlingAPI(client, g_iCurrentPage[client]);
		}
		case MenuAction_End:
			delete menu;
	}
}

void ListAliveSurvivor(int client)
{
	char sUserId[16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(MenuHandler_ListAliveSurvivor);
	menu.SetTitle("????????????");
	menu.AddItem("allplayer", "??????");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FormatEx(sUserId, sizeof(sUserId), "%d", GetClientUserId(i));
			FormatEx(sName, sizeof(sName), "%N", i);
			menu.AddItem(sUserId, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_ListAliveSurvivor(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[16];
			if(menu.GetItem(param2, sItem, sizeof(sItem)))
			{
				if(strcmp(sItem, "allplayer") == 0)
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							CheatCommand(i, g_sItemName[client]);
					}
				}
				else
					CheatCommand(GetClientOfUserId(StringToInt(sItem)), g_sItemName[client]);

				PageExitBackSwitch(client, g_iFunction[client], g_iCurrentPage[client]);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				PageExitBackSwitch(client, g_iFunction[client], g_iCurrentPage[client]);
		}
		case MenuAction_End:
			delete menu;
	}
}

void PageExitBackSwitch(int client, int iFunction, int index)
{
	switch(iFunction)
	{
		case 1:
			Gun_Menu(client, index);
		case 2:
			Melee_Menu(client, index);
		case 3:
			Action_Items(client, index);
	}
}

void ReloadAmmo(int client)
{
	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{

		char sWeapon[32];
		GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
		if(strcmp(sWeapon, "weapon_rifle_m60") == 0)
		{
			if(g_iClipSize_RifleM60 <= 0)
				g_iClipSize_RifleM60 = 150;

			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClipSize_RifleM60);
		}
		else if(strcmp(sWeapon, "weapon_grenade_launcher") == 0)
		{
			if(g_iClipSize_GrenadeLauncher <= 0)
				g_iClipSize_GrenadeLauncher = 1;
			
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClipSize_GrenadeLauncher);

			int iAmmo_Max = FindConVar("ammo_grenadelauncher_max").IntValue;
			if(iAmmo_Max <= 0)
				iAmmo_Max = 30;

			SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + 68, iAmmo_Max);
		}
	}
}

void CheatCommand(int client, const char[] sCommand)
{
	if(client == 0 || !IsClientInGame(client))
		return;

	char sCmd[32];
	if(SplitString(sCommand, " ", sCmd, sizeof(sCmd)) == -1)
		strcopy(sCmd, sizeof(sCmd), sCommand);

	if(strcmp(sCmd, "give") == 0 && strcmp(sCommand[5], "ammo") == 0)
		ReloadAmmo(client); //M60???????????????????????????

	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetCommandFlags(sCmd, flags);
	SetUserFlagBits(client, bits);
	if(strcmp(sCmd, "give") == 0 && strcmp(sCommand[5], "health") == 0)
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); //??????????????????give health?????????100???
}

void LoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) 
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn") == false)
		SetFailState("Failed to find signature: RoundRespawn");
	g_hSDK_Call_RoundRespawn = EndPrepSDKCall();
	if(g_hSDK_Call_RoundRespawn == null)
		SetFailState("Failed to create SDKCall: RoundRespawn");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SetHumanSpec") == false)
		SetFailState("Failed to find signature: SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_SetHumanSpec = EndPrepSDKCall();
	if(g_hSDK_Call_SetHumanSpec == null)
		SetFailState("Failed to create SDKCall: SetHumanSpec");
	
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TakeOverBot") == false)
		SetFailState("Failed to find signature: TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDK_Call_TakeOverBot = EndPrepSDKCall();
	if(g_hSDK_Call_TakeOverBot == null)
		SetFailState("Failed to create SDKCall: TakeOverBot");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::GoAwayFromKeyboard");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDK_Call_GoAwayFromKeyboard = EndPrepSDKCall();
	if(g_hSDK_Call_GoAwayFromKeyboard == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::GoAwayFromKeyboard");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::SetObserverTarget") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::SetObserverTarget");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_Call_SetObserverTarget = EndPrepSDKCall();
	if(g_hSDK_Call_SetObserverTarget == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::SetObserverTarget");

	Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
	if(pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
		PrepWindowsCreateBotCalls(pReplaceWithBot); // We're on L4D2 and linux
	else
		PrepLinuxCreateBotCalls(hGameData);

	StartPrepSDKCall(SDKCall_Entity);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_InfectedAttackSurvivorTeam) == false)
		SetFailState("Failed to find signature: %s", NAME_InfectedAttackSurvivorTeam); 
	g_hSDK_Call_InfectedAttackSurvivorTeam = EndPrepSDKCall();
	if(g_hSDK_Call_InfectedAttackSurvivorTeam == null)
		SetFailState("Failed to create SDKCall: %s", NAME_InfectedAttackSurvivorTeam);

	delete hGameData;
}

void LoadStringFromAdddress(Address pAddr, char[] sBuffer, int iMaxlength)
{
	int i;
	while(i < iMaxlength)
	{
		char val = LoadFromAddress(pAddr + view_as<Address>(i), NumberType_Int8);
		if(val == 0)
		{
			sBuffer[i] = 0;
			break;
		}
		sBuffer[i] = val;
		i++;
	}
	sBuffer[iMaxlength - 1] = 0;
}

Handle PrepCreateBotCallFromAddress(StringMap hSiFuncHashMap, const char[] sSIName)
{
	Address pAddr;
	StartPrepSDKCall(SDKCall_Static);
	if(!hSiFuncHashMap.GetValue(sSIName, pAddr) || !PrepSDKCall_SetAddress(pAddr))
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", sSIName);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address pJumpTableAddr)
{
	StringMap hInfectedHashMap = CreateTrie();
	// We have the address of the jump table, starting at the first PUSH instruction of the
	// PUSH mem32 (5 bytes)
	// CALL rel32 (5 bytes)
	// JUMP rel8 (2 bytes)
	// repeated pattern.
	
	// Each push is pushing the address of a string onto the stack. Let's grab these strings to identify each case.
	// "Hunter" / "Smoker" / etc.
	for(int i; i < 7; i++)
	{
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address pCaseBase = pJumpTableAddr + view_as<Address>(i * 12);
		Address pSIStringAddr = view_as<Address>(LoadFromAddress(pCaseBase + view_as<Address>(1), NumberType_Int32));
		char sSIName[32];
		LoadStringFromAdddress(pSIStringAddr, sSIName, sizeof(sSIName));

		Address pFuncRefAddr = pCaseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int oFuncRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
		Address pCallOffsetBase = pCaseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(oFuncRelOffset);
		PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", sSIName, pNextBotCreatePlayerBotTAddr);
		hInfectedHashMap.SetValue(sSIName, pNextBotCreatePlayerBotTAddr);
	}

	g_hSDK_Call_CreateSmoker = PrepCreateBotCallFromAddress(hInfectedHashMap, "Smoker");
	if(g_hSDK_Call_CreateSmoker == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSmoker);

	g_hSDK_Call_CreateBoomer = PrepCreateBotCallFromAddress(hInfectedHashMap, "Boomer");
	if(g_hSDK_Call_CreateBoomer == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateBoomer);

	g_hSDK_Call_CreateHunter = PrepCreateBotCallFromAddress(hInfectedHashMap, "Hunter");
	if(g_hSDK_Call_CreateHunter == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateHunter);

	g_hSDK_Call_CreateTank = PrepCreateBotCallFromAddress(hInfectedHashMap, "Tank");
	if(g_hSDK_Call_CreateTank == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank);
	
	g_hSDK_Call_CreateSpitter = PrepCreateBotCallFromAddress(hInfectedHashMap, "Spitter");
	if(g_hSDK_Call_CreateSpitter == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSpitter);
	
	g_hSDK_Call_CreateJockey = PrepCreateBotCallFromAddress(hInfectedHashMap, "Jockey");
	if(g_hSDK_Call_CreateJockey == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateJockey);

	g_hSDK_Call_CreateCharger = PrepCreateBotCallFromAddress(hInfectedHashMap, "Charger");
	if(g_hSDK_Call_CreateCharger == null)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateCharger);
}

void PrepLinuxCreateBotCalls(GameData hGameData = null)
{
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSmoker) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateSmoker);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateSmoker = EndPrepSDKCall();
	if(g_hSDK_Call_CreateSmoker == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSmoker);
	
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateBoomer) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateBoomer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateBoomer = EndPrepSDKCall();
	if(g_hSDK_Call_CreateBoomer == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateBoomer);
		
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateHunter) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateHunter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateHunter = EndPrepSDKCall();
	if(g_hSDK_Call_CreateHunter == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateHunter);
	
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSpitter) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateSpitter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateSpitter = EndPrepSDKCall();
	if(g_hSDK_Call_CreateSpitter == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSpitter);
	
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateJockey) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateJockey);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateJockey = EndPrepSDKCall();
	if(g_hSDK_Call_CreateJockey == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateJockey);
		
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateCharger) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateCharger);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateCharger = EndPrepSDKCall();
	if(g_hSDK_Call_CreateCharger == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateCharger);
		
	StartPrepSDKCall(SDKCall_Static);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateTank) == false)
		SetFailState("Failed to find signature: %s", NAME_CreateTank);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_Call_CreateTank = EndPrepSDKCall();
	if(g_hSDK_Call_CreateTank == null)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateTank);
}

// ====================================================================================================
//					WEAPON HANDLING
// ====================================================================================================
public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier); //send speedmodifier to be modified
}

public void WH_OnStartThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReadyingThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	speedmodifier = SpeedModifier(client, speedmodifier);
}

float SpeedModifier(int client, float speedmodifier)
{
	if(g_fSpeedUp[client] > 1.0)
		speedmodifier = speedmodifier * g_fSpeedUp[client];// multiply current modifier to not overwrite any existing modifiers already

	return speedmodifier;
}
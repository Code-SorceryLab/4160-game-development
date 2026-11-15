package bughunt

// Every piece of text the player sees, in both languages.

Text :: enum {
	Play,
	Settings,
	Quit,
	Difficulty,
	Easy,
	Hard,
	Language,
	Language_Name,
	Shake,
	Assist,
	On,
	Off,
	Back,
	Health,
	Coins,
	Key,
	Level,
	Game_Over,
	You_Win,
	Press_Enter,
}

TEXT := [Language][Text]string {
	.English = {
		.Play          = "Play",
		.Settings      = "Settings",
		.Quit          = "Quit",
		.Difficulty    = "Difficulty",
		.Easy          = "Easy",
		.Hard          = "Hard",
		.Language      = "Language",
		.Language_Name = "English",
		.Shake         = "Screen shake",
		.Assist        = "Assist mode",
		.On            = "On",
		.Off           = "Off",
		.Back          = "Back",
		.Health        = "Health",
		.Coins         = "Coins",
		.Key           = "Key",
		.Level         = "Level",
		.Game_Over     = "Game over",
		.You_Win       = "You win!",
		.Press_Enter   = "Press ENTER",
	},
	.French = {
		.Play          = "Jouer",
		.Settings      = "Paramètres",
		.Quit          = "Quitter",
		.Difficulty    = "Difficulté",
		.Easy          = "Facile",
		.Hard          = "Difficile",
		.Language      = "Langue",
		.Language_Name = "Français",
		.Shake         = "Tremblement de l'écran",
		.Assist        = "Mode assistance",
		.On            = "Activé",
		.Off           = "Désactivé",
		.Back          = "Retour",
		.Health        = "Santé",
		.Coins         = "Pièces",
		.Key           = "Clé",
		.Level         = "Niveau",
		.Game_Over     = "Partie terminée",
		.You_Win       = "Victoire !",
		.Press_Enter   = "Appuyez sur ENTRÉE",
	},
}

tr :: proc(g: ^Game, t: Text) -> string {
	return TEXT[g.settings.language][t]
}

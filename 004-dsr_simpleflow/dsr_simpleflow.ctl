#TIME	NODE(S)	DEVICE	MODE	ELEMENT	HANDLER		VALUE
100	sk1 	ath0	write	sf	add_flow	sk1:eth sk14:eth 1000 100 0 100 1
119	sk1	ath0	read	sf	txflows
119	sk1	ath0	read	sf	rxflows
119	sk14	ath0	read	sf	txflows
119	sk14	ath0	read	sf	rxflows


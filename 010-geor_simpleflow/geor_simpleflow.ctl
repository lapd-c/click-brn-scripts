#TIME	NODE(S)	DEVICE	MODE	ELEMENT		HANDLER		VALUE
0	sk1 	ath0	write	geor/gfwd	debug		4		
0	sk1 	ath0	write	geor/grt	add		00:0F:00:00:03:00 200 75 0
5	sk1	ath0	write	sf		add_flow	sk1:eth sk4:eth 1000 100 2 100 true
10	sk1	ath0	read	sf		txflows		
10	sk2	ath0	read	sf		rxflows		
10	sk3	ath0	read	sf		rxflows		
10	sk4	ath0	read	sf		rxflows		

#TIME	NODE(S)		DEVICE	MODE	ELEMENT	HANDLER		VALUE
200	FIRSTNODE 	ath0	write	sf	add_flow	FIRSTNODE:eth LASTNODE:eth 500 100 2 15000 true
229	FIRSTNODE	ath0	read	sf	stats
229	LASTNODE	ath0	read	sf	stats

#!/bin/bash
# Prosty przykład, może wymagać dostosowania
# Upewnij się, że cava jest skonfigurowana do wyjścia w formacie odpowiednim dla Waybara
# np. w ~/.config/cava/config: output = raw, channels = mono, format = ascii, ascii_max_range = 7 (lub więcej)
# oraz odpowiednia liczba słupków (bars)
cava -p ~/.config/cava/config| while read -r line; do
    # Przetwarzanie linii z CAVA, aby pasowała do formatu Waybara (np. bloki Unicode)
    # Poniżej bardzo uproszczony przykład, który może nie działać od razu
    # Możesz potrzebować sed lub awk do transformacji outputu CAVY na pożądane znaki
    echo "{\"text\": \"$line\"}" 
done

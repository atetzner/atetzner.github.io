---
title:  "Vodafone Business: Statische IP mit eigenem Router hinter FritzBox"
date:   2021-10-27 21:00:00 +0100
categories: IT Network
---

Ich bin eigentlich seit Jahren zufriedener Kunde bei Unitymedia. Nachdem diese aber von Vodafone gekauft wurden, musste mein Tarif umgestellt werden. Hört sich nach einer Kleinigkeit an, hat aber mein Setup mit einer statischen IP zerstört.


## tl;dr
Verwendet man einen zweiten Router hinter der Vodafone FritzBox für eine öffentliche, statische IP kann es zu Problemen bei der Konfiguration kommen.

1. Verwende nur LAN1 der FritzBox für LAN. Der WAN Port des eigenen Routers für die *öffentliche, statische IP* sollte an LAN2 angeschlossen werden.
2. Wenn man seinen externen Router in der Liste der bekannten Netzwerkgeräte nicht mit der öffentlichen, statischen IP findet (sondern bspw. nur mit der privaten LAN-IP), muss man (etwas umständlich) die Liste Löschen und geordnet neu aufbauen. Erst wenn man einen Eintrag für den Router mit der öffentlichen IP hat, kann man einen korrekten Eintrag für einen Exposed Host anlegen.


## Mein Setup
Ich bin bekennender AVM-Jünger und benutze gern deren Fritz-Produkte. Insofern kommt es mir gelegen, dass man als Vodafone Business Kunde eine FritzBox bekommt.

Leider hat mir die FritzBox was Netzwerkkonfiguration angeht doch ein bisschen zu wenig Einstellungsmöglichkeiten (statisches DHCP, statische DNS, Firewall, …), so dass ich für Routing, DHCP, DNS, etc. einen Mikrotik Router benutze. Dieser hing bisher an LAN4 der Vodafone FritzBox.

Damit ich für WLAN nicht noch ein separates Gerät brauche, möchte ich die WLAN Funktion der FritzBox benutzen. Daher ist die FritzBox über den LAN3 Anschluss auch noch mit dem LAN verbunden.

Zugegebenermaßen vermutlich kein alltägliches Setup, aber für mich funktioniert es gut 🙂

## Vorgeplänkel
Mein Fall ist vielleicht etwas blöd gelaufen, aber ich könnte mir gut vorstellen, dass anderen etwas ähnliches passiert, weshalb ich hier kurz das Problem und die Lösung schildern möchte. Angefangen hat es damit, dass es meinen alten Unitymedia 50MBit Business Tarif nicht mehr geben sollte und ich per Telefonat einem Upgrade auf einen 300MBit Business Tarif zugestimmt habe. Da meine alte FritzBox 6490 diese Geschwindigkeit nicht unterstützt hätte, wurde mir eine neue FritzBox zugeschickt, bei Vodafone meinem Account zugeordnet und entsprechend im Backend von Vodafone konfiguriert. Da sich im Nachhinein herausgestellt hat, dass der Tarif so doch ein paar Nachteile für mich gebracht hätte, bin ich (bevor der Tarif umgestellt wurde) doch noch auf einen 100MBit Tarif gewechselt, was wiederum von meiner alten FritzBox unterstützt wurde. Da Vodafone-seitig darauf gewartet wurde, dass ich die neue FritzBox in Betrieb nehme, wollte ich die benutzen – habe dann aber nach dem Anschluss gemerkt, dass mir nur 1MBit provisioniert wurde. Darüber hinaus war (entgegen der Versprechung am Telefon) keine Einstellungen aus meiner alten FritzBox übernommen worden und ein Backup der alten FritzBox ließ sich auch nicht einspielen.

Am nächsten Tag hab ich dann bei Vodafon angerufen und gefragt, welche FritzBox ich denn jetzt nehmen soll – und da ich ein fauler Mensch bin und mir die Neukonfiguration der neuen FritzBox sparen wollte, hab ich auch gleich dazu gesagt, dass ich bevorzugt meine alte FritzBox behalten möchte. Während ich eigentlich mit dem Support (per Festznetz) telefoniert habe, wurde die Konfiguration meiner alten FritzBox geändert, der neue Tarif aktiviert und die FritzBox neu gestartet. Dass dabei die Telefonverbindung mit weg war, war denen im Support wohl nur bedingt klar …

## Die Probleme begannen
Nach dem Neustart der FritzBox hab ich erstmal geschaut, was die denn alles an meiner Konfiguration ~~kaputt gemacht~~ geändert haben. Und siehe da: Die LAN Ports, an denen die öffentliche IP anliegt, wurden geändert (*Internet > Zugangsart > Portkonfiguration*): Bisher hatte ich meinen Router an LAN4 (WAN; statische, öffentliche IP) und LAN3 (LAN) verbunden. Nach dem Neustart waren jedoch LAN2, LAN3 und LAN4 so konfiguriert, dass diese alle für öffentliche IPs zu benutzen gewesen wären. Glücklicherweise ist die Firewall der FritzBox trotzdem für alle LAN-Ports aktiv.

Nach dem ersten von vielen Telefonaten sagte man mir dann, dass es wohl Standard wäre, dass nur LAN1 für das lokale Netz sei und LAN2, LAN3 und LAN4 für die öffentlichen IPs. Da ich die öffentliche IP auf LAN2 und LAN3 deaktiviert hatte, hätte es eigentlich keinen Unterschied machen sollen, wie ich das verkabel hatte – aber gut, an sowas soll es ja nicht scheitern und ich hab dann eben LAN1 für LAN und LAN2 für WAN benutzt. Und siehe da, plötzlich kam ich doch tatsächlich über meinen Mikrotik Router wieder mit meiner statischen IP ins Internet.

## Die Probleme gingen weiter
Da ich davon ausgegangen bin, dass die Portkonfiguration in der FritzBox oberfläche sich tatsächlich auswirkt bzw. es unerheblich ist, an welchen Ports ich meine öffentliche, statische IP abgreife, hatte ich schon einiges an der Konfiguration der FritzBox verstellt. Unter anderem hatte ich auch den Exposed Host gelöscht – ein grober Fehler, wie sich herausstellen sollte, denn ich konnte jetzt zwar mit meiner öffentlichen, statischen IP surfen, jedoch kam ich vom Internet jetzt nicht mehr zurück in mein LAN. Den Exposed Host wieder richtig einzustellen hat leider auch nicht funktioniert. Von Vodafone bekam ich zwar eine Anleitung, wie ich den Exposed Host einzurichten hätte, aber die in der Anleitung beschriebenen Schritte waren über die UI der FritzBox gar nicht ausführbar: Laut Anleitung sollte man, wenn man unter *Heimnetz > Netzwerk* den separaten Router (bei mir Mikrotik Router) nicht mit der öffentlichen, statischen IP sieht, die IP des Geräts in der UI ändern. Das geht aber gar nicht, da das zugehörige Eingabefeld ausgegraut ist. Wenn ich beim Exposed Host das Netzwerkgerät mit der MAC-Adresse des WAN Ports meines Mikrotik Routers (aber mit einer privaten IP) gewählt habe, kam ich trotzdem nicht vom Internet ins LAN zurück.

Konkret äußerte sich das so, dass
* ein ping auf meine öffentliche IP keine Antwort erzeugte.
* ein traceroute auf die Gateway-Adresse der FritzBox einen vollständigen Pfad bis zur Box ergab.
* ein traceroute auf meine öffentliche Adresse als letzten Hop eine Vodafone-IP ergab, welche beim traceroute auf die Gateway-Adresse der letzte Hop vor der FritzBox war.

## Die Lösung
Das eigentliche Problem hier ist nicht Vodafone, sondern die FritzBox. Offensichtlich kommt diese mit meiner – zugegebenermaßen vielleicht etwas eigenwilligen – Verkabelung nicht zurecht. In Folge dessen wird mein Mikrotik Router in der UI der FritzBox immer mit seiner privaten LAN-IP angezeigt und man bekommt nie einen Eintrag mit dessen WAN-IP, wie es auch in der Anleitung von Vodafone erwähnt wird.

Um den Exposed Host richtig zu konfigurieren, ist dies aber zumindest kurzfristig notwendig. Um das hin zu bekommen geht man wie folgt vor:

* WLAN Name der FritzBox (temporär) ändern
* LAN und WAN des externen Routers (bei mir Mikrotik Router) von der FritzBox trennen
* FritzBox neu starten
* Mit Laptop mit dem (temporären) WLAN der FritzBox verbinden und die Weboberfläche aufrufen
* Unter *Heimnetz > Netzwerk* ganz unten den Button zum Leeren der Liste der bekannten Netzwerkgeräte klicken. Im Zweifelsfall auch alle übrigen Geräte aus der * Liste löschen (für mich kein Problem, da bei mir der Mikrotik Router die Verwaltung der Netzwerkgeräte übernimmt).
* Den WAN Port des externen Routers mit LAN2 der FritzBox verbinden
* Nochmals *Heimnetz > Netzwerk* aufrufen (ggf. Seite aktualisieren). Jetzt sollte der externe Router mit seiner öffentlichen, statischen IP in der Liste auftauchen
* Jetzt kann man unter *Internet > Freigaben > Portfreigaben > Gerät für Freigabe* hinzufügen den externen Router in der Dropdown-Liste auswählen und er wird mit der korrekten MAC-Adresse und der öffentlichen, statischen IP angezeigt. Noch den Haken bei Exposed Host setzen und mit OK bestätigen – Fertig.
* Danach kann man das Kabel, welches die FritzBox mit dem LAN verbindet, wieder in LAN1 stecken und den WLAN Name zurückändern.

Übrigens ist es nicht weiter tragisch, wenn später unter *Heimnetz > Netzwerk* der externe Router wieder unter seiner lokalen, privaten IP gelistet wird. In meinem Fall ist es sogar so, dass der als Exposed Host gekennzeichnete Eintrag in der Liste wechselnde IPs hat – mal die des Routers, mal die meines Heimservers …

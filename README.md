# Progetto di Reti Logiche
### :it: Progetto di Ingegneria Informatica per il corso "Reti Logiche" al Politecnico di Milano
*Anno accademico: 2024/2025*

*Votazione: 30/30 con lode*

**Riassunto**:

Implementazione in VHDL di un modulo hardware capace di interfacciarsi con una memoria sincrona via protocollo START/DONE. Prima di tutto, il sistema configura la funzione differenziale, scegliendo tra Ordine 3 e Ordine 5. Successivamente, utilizza la funzione su una sequenza di bit di 8 bit, espressa in C2. La sequenza di parole ritornata dalla funzione deve essere saturata a 8 bit e salvata in memoria. I requisiti di progettazione includono il comportamento strettamente deterministico (latch-free) e il requisito sul massimo periodo di clock di 20 ns.
***

### :gb: Engineering of Computing Systems project for the course "Digital Logic Design" at Politecnico di Milano
*Academic year: 2024/2025*

*Grade: 30/30 cum laude*

**Summary**:

Implementation in VHDL of a hardware module which is able to interface with a synchronous memory via a START/DONE protocol. First of all, the system configures the differential function, choosing between Order 3 and Order 5. After that, it uses the function to a sequence of 8-bit words, expressed in C2. The sequence of words returned by the function has to be saturated to 8 bits and written back to the memory.
Design requirements include strict deterministic behaviour (latch-free) and the maximum clock period requirement of 20 ns.

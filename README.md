# 🧰 MTA Inventory System

Bem-vindo ao sistema de inventário para MTA: San Andreas! 🚗📦
Este recurso foi desenvolvido para ser flexível, intuitivo e fácil de integrar em qualquer servidor.

---

## ✨ Principais Funcionalidades

- 🖥️ Interface moderna e responsiva
- 🎒 Suporte a múltiplos tipos de itens
- 💾 Sistema de armazenamento persistente (database)
- 🖼️ Fácil customização de ícones e configurações
- 🔗 Integração com outros módulos do servidor

---

## 🚀 Começando

1. Instale o recurso na pasta `resources` do seu servidor.
2. Configure os itens e parâmetros em `config/itens.lua` e `config/index.lua`.
3. Inicie o recurso e aproveite!

---

## 📦 Exemplos de Uso dos Exports

Aqui você encontra exemplos práticos de como utilizar os exports do sistema de inventário, seguindo o padrão da Wiki MTA.

### give



**Sintaxe:**

```lua
bool exports['mta-inventory']:give (element theElement, string itemName, number amount, table itemData)
```

**Parâmetros:**

- `element theElement`: [Element](https://wiki.multitheftauto.com/wiki/Element) - Jogador ou entidade que receberá o item.
- `string itemName`: [string](https://www.lua.org/manual/5.1/manual.html#2.1) - Nome do item a ser dado.
- `number amount`: [number](https://www.lua.org/manual/5.1/manual.html#2.1) - Quantidade do item.
- `table itemData`: [table](https://www.lua.org/manual/5.1/manual.html#2.1) - Dados adicionais do item (opcional).

**Retorno:**

- `bool`: Retorna `true` se o item foi dado com sucesso, `false` caso contrário.

**Exemplo:**

```lua
local gived = exports['mta-inventory']:give (getRandomPlayer (), 'ak47', 1, { blocked = true });
if (gived) then
	return print 'Item received with success.';
end
return print 'Failed to receive item, check params'.
```

---

## 🤝 Contribua

Pull requests, sugestões e melhorias são bem-vindas! Sinta-se livre para abrir issues ou enviar PRs.

---

## 📄 Licença

MIT. Sinta-se livre para contribuir!
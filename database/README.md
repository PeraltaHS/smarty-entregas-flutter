# Banco de Dados — Smarty Entregas

## O que é esta pasta?

A pasta `database/` centraliza o versionamento da estrutura do banco PostgreSQL no Git. O arquivo principal é o `schema.sql`, que deve sempre refletir o estado atual do banco de produção.

Assim, qualquer membro da equipe consegue:
- Saber exatamente como o banco está estruturado sem precisar acessar o servidor
- Recriar o banco do zero em uma máquina nova
- Ver no histórico do Git quando e por que uma tabela ou coluna foi modificada

---

## Como exportar o banco pelo pgAdmin

Faça isso **sempre que modificar o banco** (nova tabela, nova coluna, trigger, etc.):

1. Abra o pgAdmin e conecte ao servidor
2. No painel esquerdo, clique com o botão direito no banco `smartyentregas`
3. Selecione **Backup...**
4. Em **Filename**, aponte para o arquivo: `database/schema.sql` (na raiz do projeto)
5. Em **Format**, selecione **Plain**
6. Vá na aba **Data Options** e marque **Schema and data** (ou só **Only schema** se não quiser dados)
7. Clique em **Backup**
8. Commit o `schema.sql` junto com o código que dependeu dessa mudança

---

## Como restaurar o banco pelo pgAdmin

Faça isso ao configurar o ambiente em uma máquina nova, ou ao reverter o banco:

1. Abra o pgAdmin e conecte ao servidor
2. Se já existir um banco `smartyentregas`, clique com o botão direito nele → **Delete/Drop** → confirme
3. Clique com o botão direito em **Databases** → **Create** → **Database...**
4. Nome: `smartyentregas` → salve
5. Clique com o botão direito no banco recém-criado → **Restore...**
6. Em **Filename**, aponte para `database/schema.sql`
7. Clique em **Restore**
8. Aguarde a conclusão — o banco estará idêntico ao do arquivo

---

## Regra de ouro

> **Sempre que modificar o banco, exporte e commite o `schema.sql` atualizado junto com o código que depende da mudança.**

Exemplo de commit correto:
```
feat: adiciona coluna cnh na tabela usuarios

- ALTER TABLE usuarios ADD COLUMN cnh VARCHAR(20)
- Endpoint /auth/register/motoboy agora persiste o número da CNH
- database/schema.sql atualizado via pgAdmin
```

---

## Pasta `backups/`

A pasta `database/backups/` é **ignorada pelo Git** (está no `.gitignore`). Use-a para salvar backups completos locais antes de testar mudanças arriscadas. Esses arquivos ficam só na sua máquina.

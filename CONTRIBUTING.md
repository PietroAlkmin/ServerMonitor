# ?? Contribuindo para o Apache Monitor Pro

Obrigado por considerar contribuir para o Apache Monitor Pro! Este documento explica como voc� pode ajudar a melhorar o projeto.

## ?? Tipos de Contribui��o

### ?? **Reportar Bugs**
- Use o [GitHub Issues](../../issues)
- Descreva o comportamento esperado vs atual
- Inclua logs e screenshots quando poss�vel
- Mencione vers�o do Windows e .NET

### ?? **Sugerir Melhorias**
- Abra uma [Discussion](../../discussions) primeiro
- Explique o problema que a feature resolve
- Descreva a solu��o proposta
- Considere implementa��es alternativas

### ?? **Contribuir com C�digo**
- Fork o reposit�rio
- Crie branch descritiva
- Siga as conven��es de c�digo
- Adicione testes quando aplic�vel
- Atualize documenta��o

## ?? Processo de Desenvolvimento

### **1. Setup do Ambiente**
```bash
# Clone seu fork
git clone https://github.com/SEU_USUARIO/apache-monitor-pro.git
cd apache-monitor-pro

# Configurar upstream
git remote add upstream https://github.com/USUARIO_ORIGINAL/apache-monitor-pro.git

# Instalar depend�ncias
dotnet restore
```

### **2. Criando uma Branch**
```bash
# Sempre baseie em main atualizada
git checkout main
git pull upstream main

# Crie branch descritiva
git checkout -b feature/adicionar-suporte-nginx
# ou
git checkout -b fix/corrigir-deteccao-apache
# ou  
git checkout -b docs/melhorar-readme
```

### **3. Desenvolvendo**
- Mantenha commits pequenos e focados
- Use mensagens de commit descritivas
- Teste suas mudan�as localmente
- Siga as conven��es do projeto

### **4. Testando**
```bash
# Compilar
dotnet build

# Testar localmente
dotnet run

# Executar testes (quando dispon�veis)
dotnet test
```

### **5. Submetendo PR**
```bash
# Push da sua branch
git push origin feature/sua-feature

# Abra PR no GitHub
# Descreva as mudan�as claramente
# Referencie issues relacionadas
```

## ?? Conven��es de C�digo

### **C# / .NET**
- Use **PascalCase** para classes, m�todos, propriedades
- Use **camelCase** para vari�veis locais
- Use **_camelCase** para campos privados
- Adicione coment�rios XML para m�todos p�blicos
- Limite linhas a 100 caracteres quando poss�vel

### **Exemplo de C�digo**
```csharp
/// <summary>
/// Verifica se o servi�o Apache est� rodando
/// </summary>
/// <param name="serviceName">Nome do servi�o a verificar</param>
/// <returns>True se o servi�o est� rodando</returns>
public async Task<bool> IsApacheRunningAsync(string serviceName)
{
    var queryProcess = new ProcessStartInfo
    {
        FileName = "sc",
        Arguments = $"query \"{serviceName}\"",
        RedirectStandardOutput = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };

    using var process = Process.Start(queryProcess);
    await process.WaitForExitAsync();
    
    if (process.ExitCode == 0)
    {
        var output = await process.StandardOutput.ReadToEndAsync();
        return output.Contains("RUNNING");
    }
    
    return false;
}
```

### **Logging**
```csharp
// Use structured logging
_logger.LogInformation("? Apache detectado: {ServiceName}", serviceName);
_logger.LogWarning("?? Tentativa {Attempt} de {MaxAttempts}", attempt, maxAttempts);
_logger.LogError(ex, "? Erro ao reiniciar Apache: {ServiceName}", serviceName);
```

### **Mensagens de Commit**
```bash
# Bom
feat: adicionar suporte para detec��o do Nginx
fix: corrigir falha na reinicializa��o do Apache
docs: atualizar README com instru��es de configura��o
refactor: extrair l�gica de detec��o para classe separada

# Ruim
fix bug
update code
changes
```

## ?? Testes

### **Testando Localmente**
1. Configure um ambiente Apache local
2. Configure webhook Discord de teste
3. Execute o servi�o em modo debug
4. Simule falhas parando/iniciando Apache
5. Verifique logs e notifica��es

### **Cen�rios de Teste**
- ? Apache como servi�o Windows
- ? Apache como processo direto
- ? Falha de conex�o HTTP
- ? Timeout de requisi��o
- ? Reinicializa��o bem-sucedida
- ? Falha na reinicializa��o
- ? M�ltiplas tentativas
- ? Notifica��es Discord

## ?? Documenta��o

### **Quando Atualizar**
- Novas funcionalidades
- Mudan�as de configura��o
- Novos requisitos
- Altera��es na API
- Corre��es importantes

### **Arquivos a Considerar**
- `README.md` - Documenta��o principal
- `CONTRIBUTING.md` - Este arquivo
- Coment�rios no c�digo
- Mensagens de log
- Configura��es de exemplo

## ?? Reportando Problemas de Seguran�a

Para vulnerabilidades de seguran�a, **N�O** abra issues p�blicas. 

Envie email diretamente para: [CONFIGURAR EMAIL DE SEGURAN�A]

Inclua:
- Descri��o da vulnerabilidade
- Passos para reproduzir
- Impacto potencial
- Sugest�es de corre��o (se houver)

## ?? Roadmap e Prioridades

### **Pr�ximas Features (Por Ordem de Prioridade)**
1. **Configura��o externa** (appsettings.json)
2. **Interface gr�fica** para configura��o
3. **Suporte a m�ltiplos sites** simult�neos
4. **Suporte Nginx/IIS** al�m do Apache
5. **Dashboard web** para monitoramento
6. **M�tricas e relat�rios** hist�ricos
7. **Integra��o Slack/Teams** al�m do Discord
8. **Testes unit�rios** abrangentes

### **Melhorias T�cnicas**
- Refatora��o da arquitetura monol�tica
- Implementa��o de interfaces/DI
- Melhoria do sistema de logs
- Otimiza��o de performance
- Documenta��o da API interna

## ?? Comunica��o

### **Canais Dispon�veis**
- ?? **Bugs**: [GitHub Issues](../../issues)
- ?? **Features**: [GitHub Discussions](../../discussions)
- ?? **Documenta��o**: Pull Requests
- ?? **Geral**: [GitHub Discussions](../../discussions)

### **Tempo de Resposta Esperado**
- Issues cr�ticos: 24-48 horas
- Pull Requests: 3-5 dias �teis
- Discuss�es: 1 semana
- Features grandes: 2-4 semanas

### **Como Conseguir Ajuda**
1. Verifique issues/discussions existentes
2. Leia a documenta��o completa
3. Teste com configura��o m�nima
4. Colete logs detalhados
5. Crie issue com template completo

## ?? Reconhecimento

Contribuidores s�o reconhecidos de v�rias formas:
- Nome no README.md
- Men��o em releases
- Badge de contributor
- Refer�ncia em commits

### **Principais Contribuidores**
[Lista ser� atualizada conforme contribui��es]

---

**Obrigado por contribuir! ??**

Toda contribui��o, por menor que seja, faz diferen�a para a comunidade.
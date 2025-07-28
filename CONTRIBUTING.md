# ?? Contribuindo para o Apache Monitor Pro

Obrigado por considerar contribuir para o Apache Monitor Pro! Este documento explica como você pode ajudar a melhorar o projeto.

## ?? Tipos de Contribuição

### ?? **Reportar Bugs**
- Use o [GitHub Issues](../../issues)
- Descreva o comportamento esperado vs atual
- Inclua logs e screenshots quando possível
- Mencione versão do Windows e .NET

### ?? **Sugerir Melhorias**
- Abra uma [Discussion](../../discussions) primeiro
- Explique o problema que a feature resolve
- Descreva a solução proposta
- Considere implementações alternativas

### ?? **Contribuir com Código**
- Fork o repositório
- Crie branch descritiva
- Siga as convenções de código
- Adicione testes quando aplicável
- Atualize documentação

## ?? Processo de Desenvolvimento

### **1. Setup do Ambiente**
```bash
# Clone seu fork
git clone https://github.com/SEU_USUARIO/apache-monitor-pro.git
cd apache-monitor-pro

# Configurar upstream
git remote add upstream https://github.com/USUARIO_ORIGINAL/apache-monitor-pro.git

# Instalar dependências
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
- Teste suas mudanças localmente
- Siga as convenções do projeto

### **4. Testando**
```bash
# Compilar
dotnet build

# Testar localmente
dotnet run

# Executar testes (quando disponíveis)
dotnet test
```

### **5. Submetendo PR**
```bash
# Push da sua branch
git push origin feature/sua-feature

# Abra PR no GitHub
# Descreva as mudanças claramente
# Referencie issues relacionadas
```

## ?? Convenções de Código

### **C# / .NET**
- Use **PascalCase** para classes, métodos, propriedades
- Use **camelCase** para variáveis locais
- Use **_camelCase** para campos privados
- Adicione comentários XML para métodos públicos
- Limite linhas a 100 caracteres quando possível

### **Exemplo de Código**
```csharp
/// <summary>
/// Verifica se o serviço Apache está rodando
/// </summary>
/// <param name="serviceName">Nome do serviço a verificar</param>
/// <returns>True se o serviço está rodando</returns>
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
feat: adicionar suporte para detecção do Nginx
fix: corrigir falha na reinicialização do Apache
docs: atualizar README com instruções de configuração
refactor: extrair lógica de detecção para classe separada

# Ruim
fix bug
update code
changes
```

## ?? Testes

### **Testando Localmente**
1. Configure um ambiente Apache local
2. Configure webhook Discord de teste
3. Execute o serviço em modo debug
4. Simule falhas parando/iniciando Apache
5. Verifique logs e notificações

### **Cenários de Teste**
- ? Apache como serviço Windows
- ? Apache como processo direto
- ? Falha de conexão HTTP
- ? Timeout de requisição
- ? Reinicialização bem-sucedida
- ? Falha na reinicialização
- ? Múltiplas tentativas
- ? Notificações Discord

## ?? Documentação

### **Quando Atualizar**
- Novas funcionalidades
- Mudanças de configuração
- Novos requisitos
- Alterações na API
- Correções importantes

### **Arquivos a Considerar**
- `README.md` - Documentação principal
- `CONTRIBUTING.md` - Este arquivo
- Comentários no código
- Mensagens de log
- Configurações de exemplo

## ?? Reportando Problemas de Segurança

Para vulnerabilidades de segurança, **NÃO** abra issues públicas. 

Envie email diretamente para: [CONFIGURAR EMAIL DE SEGURANÇA]

Inclua:
- Descrição da vulnerabilidade
- Passos para reproduzir
- Impacto potencial
- Sugestões de correção (se houver)

## ?? Roadmap e Prioridades

### **Próximas Features (Por Ordem de Prioridade)**
1. **Configuração externa** (appsettings.json)
2. **Interface gráfica** para configuração
3. **Suporte a múltiplos sites** simultâneos
4. **Suporte Nginx/IIS** além do Apache
5. **Dashboard web** para monitoramento
6. **Métricas e relatórios** históricos
7. **Integração Slack/Teams** além do Discord
8. **Testes unitários** abrangentes

### **Melhorias Técnicas**
- Refatoração da arquitetura monolítica
- Implementação de interfaces/DI
- Melhoria do sistema de logs
- Otimização de performance
- Documentação da API interna

## ?? Comunicação

### **Canais Disponíveis**
- ?? **Bugs**: [GitHub Issues](../../issues)
- ?? **Features**: [GitHub Discussions](../../discussions)
- ?? **Documentação**: Pull Requests
- ?? **Geral**: [GitHub Discussions](../../discussions)

### **Tempo de Resposta Esperado**
- Issues críticos: 24-48 horas
- Pull Requests: 3-5 dias úteis
- Discussões: 1 semana
- Features grandes: 2-4 semanas

### **Como Conseguir Ajuda**
1. Verifique issues/discussions existentes
2. Leia a documentação completa
3. Teste com configuração mínima
4. Colete logs detalhados
5. Crie issue com template completo

## ?? Reconhecimento

Contribuidores são reconhecidos de várias formas:
- Nome no README.md
- Menção em releases
- Badge de contributor
- Referência em commits

### **Principais Contribuidores**
[Lista será atualizada conforme contribuições]

---

**Obrigado por contribuir! ??**

Toda contribuição, por menor que seja, faz diferença para a comunidade.
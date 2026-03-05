# Download lifelog

Repository with an environment for downloading medication information from various sources.

> **ALL DATA HERE IS RAW/BRONZE**

## ANVISA

Download all PDFs of medication lifelog, for both patients and professionals.

### Novo Fluxo de Download

Ao invés de usar o csv disponibilizado pela ANVISA como base para o scraper, é possível listar todos ( ou quase todos ) os medicamentos do bulario utilizando a seguinte busca:

<https://consultas.anvisa.gov.br/#/bulario/q/?categoriasRegulatorias=1,2,3,4,5,6,7,8,10,11,12>

Dessa forma é possível extrair ainda mais informações do que as informações de baixa qualidade do csv.

Para começar, cada página da busca possui 10 items. Não é necessário aumentar o número de resultados por página.

![Resultado da busca](image.png)

Para cada página que a busca retornou é possível construir uma nova tabala, contendo o as informações da lista.

Para baixar as bulas encontrei dois problemas:

1. O download ocorre usando o evento de click, não expondo a url
2. Não é possível identificar o arquivo baixado

```html
<a
  ng-if="produto.idBulaProfissionalProtegido"
  ng-click="downloadBula(produto.idBulaProfissionalProtegido,Authorization)"
  class="ng-scope"
>
  <img src="assets/img/pdf.png" />
</a>
```

Felizmente com o histórico de bulas é possível ter certeza que a bula x foi baixada pelo processo x. Infelizmente toda navegação nesse site é usando ng-click, dessa forma os links só são gerados com interação. AS PÁGINAS TAMBÉM SÃO TUDO NG-....

![alt text](image-1.png)

Resumindo a minha ideia:
Primeiro

## Drugs.com

Realizar furto de dados qualificado, navegando por todas as páginas e criando uma árvore de informações.

## Docker Compose

### Selenium Grid

### Selenium Nodes

## Pipeline

<https://github.com/dagster-io/dagster>

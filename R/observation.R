#' Get *observation* table
#'
#' Download data from the *observation* ("observacao") table of one or more datasets contained in the Free
#' Brazilian Repository for Open Soil Data -- ___febr___, \url{http://www.ufsm.br/febr}. This includes spatial
#' coordinates, observation date, and variables such as geology, land use and vegetation, local topography, and
#' much more. Use \code{\link[febr]{header}} if you want to check what are the variables contained in the 
#' *observation* table of a dataset before downloading it.
#' 
#' @template data_template
#' @template metadata_template
#' 
#' @param missing (optional) List with named sub-arguments indicating what should be done with an observation
#' missing spatial coordinates, `coord`, date of observation, `time`, or data on variables, `data`? Options are
#' `"keep"` (default) and `"drop"`.
#'
#' @param standardization (optional) List with named sub-arguments indicating how to perform data 
#' standardization.
#' \itemize{
#' \item `crs` Character string indicating the EPSG code of the coordinate reference system (CRS) to which
#'       spatial coordinates should be transformed. For example, `crs = "EPSG:4674"`, i.e. SIRGAS 2000, the
#'       standard CRS for Brazil -- see more at \url{http://spatialreference.org/ref/epsg/}. Defaults to 
#'       `crs = NULL`, i.e. no transformation is performed.
#' \item `time.format` Character string indicating how to format dates. For example, 
#'       \code{time.format = "\%d-\%m-\%Y"}, i.e. dd-mm-yyyy such as in 31-12-2001. Defaults to 
#'       `time.format = NULL`, i.e. no formatting is performed. See \code{\link[base]{as.Date}} for more 
#'       details.
#' \item `units` Logical value indicating if the measurement units of the continuous variable(s) should
#'       be converted to the standard measurement unit(s). Defaults to `units = FALSE`, i.e. no conversion is
#'       performed. See \code{\link[febr]{standard}} for more information.
#' \item `round` Logical value indicating if the values of the continuous variable(s) should be rounded  
#'       to the standard number of decimal places. Requires `units = TRUE`. Defaults to `round = FALSE`, i.e. 
#'       no rounding is performed. See \code{\link[febr]{standard}} for more information.
#' }
#' 
#' @param harmonization (optional) List with named sub-arguments indicating if and how to perform data 
#' harmonization.
#' \itemize{
#' \item `harmonize` Logical value indicating if data should be harmonized? Defaults to `harmonize = FALSE`,
#'       i.e. no harmonization is performed.
#' \item `level` Integer value indicating the number of levels of the identification code of the variable(s) 
#'       that should be considered for harmonization. Defaults to `level = 2`. See \sQuote{Details} for more
#'       information.
#' }
#'
#' @details 
#' \subsection{Standard identification variables}{
#' Standard identification variables and their content are as follows:
#' \itemize{
#' \item `dataset_id`. Identification code of the dataset in ___febr___ to which an observation belongs.
#' \item `observacao_id`. Identification code of an observation in ___febr___.
#' \item `sisb_id`. Identification code of an observation in the Brazilian Soil Information System
#' maintained by the Brazilian Agricultural Research Corporation (EMBRAPA) at
#' \url{https://www.bdsolos.cnptia.embrapa.br/consulta_publica.html}.
#' \item `ibge_id`. Identification code of an observation in the database of the Brazilian Institute
#' of Geography and Statistics (IBGE) at \url{http://www.downloads.ibge.gov.br/downloads_geociencias.htm#}.
#' \item `observacao_data`. Date (dd-mm-yyyy) in which an observation was made.
#' \item `coord_sistema`. EPSG code of the coordinate reference system.
#' \item `coord_x`. Longitude (°) or easting (m).
#' \item `coord_y`. Latitude (°) or northing (m).
#' \item `coord_precisao`. Precision with which x- and y-coordinates were determined (m).
#' \item `coord_fonte`. Source of the x- and y-coordinates.
#' \item `pais_id`. Country code (ISO 3166-1 alpha-2).
#' \item `estado_id`. Code of the Brazilian federative unit where an observation was made.
#' \item `municipio_id`. Name of the Brazilian county where as observation was made.
#' \item `amostra_tipo`. Type of sample taken.
#' \item `amostra_quanti`. Number of samples taken.
#' \item `amostra_area`. Sampling area.
#' }
#' Further details about the content of the standard identification variables can be found in 
#' \url{http://www.ufsm.br/febr/book/} (in Portuguese).
#' }
#' 
#' \subsection{Harmonization}{
#' Data harmonization consists of converting the values of a variable determined using some method *B* so 
#' that they are (approximately) equivalent to the values that would have been obtained if the standard method
#' *A* had been used instead. For example, converting carbon content values obtained using a wet digestion
#' method to the standard dry combustion method is data harmonization.
#' 
#' A heuristic data harmonization procedure is implemented in the **febr** package. It consists of grouping
#' variables 
#' based on a chosen number of levels of their identification code. For example, consider a variable with an 
#' identification code composed of four levels, `aaa_bbb_ccc_ddd`, where `aaa` is the first level and
#' `ddd` is the fourth level. Now consider a related variable, `aaa_bbb_eee_fff`. If the harmonization
#' is to consider all four coding levels (`level = 4`), then these two variables will remain coded as
#' separate variables. But if `level = 2`, then both variables will be re-coded as `aaa_bbb`, thus becoming the
#' same variable.
#' }
#'
#' @return A list of data frames or a data frame with data on the chosen variable(s) of the chosen dataset(s).
#'
#' @author Alessandro Samuel-Rosa \email{alessandrosamuelrosa@@gmail.com}
#' @seealso \code{\link[febr]{layer}}, \code{\link[febr]{standard}}, \code{\link[febr]{unit}}
#' @export
#' @examples
# \donttest{
# res <- observation(dataset = paste("ctb000", 4:9, sep = ""), variable = "taxon")
#' res <- observation(dataset = "ctb0013", variable = "taxon")
#' str(res)
# }
###############################################################################################################
observation <-
  function (dataset, variable, 
            stack = FALSE, missing = list(coord = "keep", time = "keep", data = "keep"),
            standardization = list(
              crs = NULL, time.format = NULL,
              units = FALSE, round = FALSE),
            harmonization = list(harmonize = FALSE, level = 2),
            progress = TRUE, verbose = TRUE) {
    
    # OPÇÕES E PADRÕES
    opts <- .opt()
    std_cols <- opts$observation$std.cols
    
    # ARGUMENTOS
    ## dataset
    if (missing(dataset)) {
      stop ("argument 'dataset' is missing")
    } else if (!is.character(dataset)) {
      stop (glue::glue("object of class '{class(dataset)}' passed to argument 'dataset'"))
    }
    
    ## variable
    if (!missing(variable) && !is.character(variable)) {
      stop (glue::glue("object of class '{class(variable)}' passed to argument 'variable'"))
    }
    
    ## stack
    if (!is.logical(stack)) {
      stop (glue::glue("object of class '{class(stack)}' passed to argument 'stack'"))
    }
    
    ## missing
    if (!missing(missing)) {
      if (is.null(missing$coord)) {
        missing$coord <- "keep"
      } else if (!missing$coord %in% c("drop", "keep")) {
        stop (glue::glue("unknown value '{missing$coord}' passed to sub-argument 'missing$coord'"))
      }
      if (is.null(missing$time)) {
        missing$time <- "keep"
      } else if (!missing$time %in% c("drop", "keep")) {
        stop (glue::glue("unknown value '{missing$time}' passed to sub-argument 'missing$time'"))
      }
      if (is.null(missing$data)) {
        missing$data <- "keep"
      } else if (!missing$data %in% c("drop", "keep")) {
        stop (glue::glue("unknown value '{missing$data}' passed to sub-argument 'missing$data'"))
      }
    }
    
    ## standardization
    if (!missing(standardization)) {
      if (is.null(standardization$crs)) {
        standardization$crs <- NULL
      } else if (!is.character(standardization$crs)) {
        y <- class(standardization$crs)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$crs'"))
      } else if (!toupper(standardization$crs) %in% opts$crs) {
        y <- standardization$crs
        stop (glue::glue("unknown value '{y}' passed to sub-argument 'standardization$crs'"))
      }
      
      if (is.null(standardization$time.format)) {
        standardization$time.format <- NULL
      } else if (!is.character(standardization$time.format)) {
        y <- class(standardization$time.format)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$time.format'"))
      }
      
      if (is.null(standardization$units)) {
        standardization$units <- FALSE
      } else if (!is.logical(standardization$units)) {
        y <- class(standardization$units)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$units'"))
      }
      if (is.null(standardization$round)) {
        standardization$round <- FALSE
      } else if (!is.logical(standardization$round)) {
        y <- class(standardization$round)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$round'"))
      }
      
      if (is.null(standardization$units)) {
        standardization$units <- FALSE
      } else if (!is.logical(standardization$units)) {
        y <- class(standardization$units)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$units'"))
      }
      if (is.null(standardization$round)) {
        standardization$round <- FALSE
      } else if (!is.logical(standardization$round)) {
        y <- class(standardization$round)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'standardization$round'"))
      }
    }
    
    ## harmonization
    if (!missing(harmonization)) {
      if (is.null(harmonization$harmonize)) {
        harmonization$harmonize <- FALSE
      } else if (!is.logical(harmonization$harmonize)) {
        y <- class(harmonization$harmonize)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'harmonization$harmonize'"))
      }
      if (is.null(harmonization$level)) {
        harmonization$level <- 2
      } else if (!pedometrics::isNumint(harmonization$level)) {
        y <- class(harmonization$level)
        stop (glue::glue("object of class '{y}' passed to sub-argument 'harmonization$level'"))
      }
    }
    
    ## progress
    if (!is.logical(progress)) {
      stop (glue::glue("object of class '{class(progress)}' passed to argument 'progress'"))
    }
    
    ## verbose
    if (!is.logical(verbose)) {
      stop (glue::glue("object of class '{class(verbose)}' passed to argument 'verbose'"))
    }
    
    ## variable + stack || variable + harmonization
    if (!missing(variable) && variable == "all") {
      if (stack) {
        stop ("data cannot be stacked when downloading all variables")
      }
      if (harmonization$harmonize) {
        stop ("data cannot be harmonized when downloading all variables")
      }
    }
    
    # PADRÕES
    ## Descarregar tabela com unidades de medida e número de casas decimais quando padronização é solicitada
    ## ou quando empilhamento é solicitado
    if (standardization$units || stack) {
      febr_stds <- .getTable(x = "1Dalqi5JbW4fg9oNkXw5TykZTA39pR5GezapVeV0lJZI")
      febr_unit <- .getTable(x = "1tU4Me3NJqk4NH2z0jvMryGObSSQLCvGqdLEL5bvOflo")
    }
    
    ## stack + stadardization
    ## Padronização não precisa ser feita no caso de descarregamento apenas das variáveis padrão
    ## Também não precisa ser feita no caso de variáveis de tipo 'texto'
    if (stack && !standardization$units && !missing(variable) && variable != "all") {
      tmp_var <- glue::glue("^{variable}")
      idx <- lapply(tmp_var, function (pattern) grep(pattern = pattern, x = febr_stds$campo_id))
      idx <- unlist(idx)
      is_all_text <- all(febr_stds$campo_tipo[idx] == "texto")
      if (!is_all_text) {
        stop ("data cannot be stacked when measurement units are not standardized")
      }
    }
    
    # CHAVES
    ## Descarregar chaves de identificação das tabelas
    sheets_keys <- .getSheetsKeys(dataset = dataset)
    n <- nrow(sheets_keys)
    
    # Descarregar planilhas com observações
    if (progress) {
      pb <- utils::txtProgressBar(min = 0, max = length(sheets_keys$observacao), style = 3)
    }
    res <- list()
    for (i in 1:length(sheets_keys$observacao)) {
      # i <- 1
      # Informative messages
      dts <- sheets_keys$ctb[i]
      if (verbose) {
        par <- ifelse(progress, "\n", "")
        message(paste(par, "Downloading dataset ", dts, "...", sep = ""))
      }
      
      # DESCARREGAMENTO
      ## Cabeçalho com unidades de medida
      unit <- .getHeader(x = sheets_keys$observacao[i])
      
      ## Dados
      tmp <- .getTable(x = sheets_keys$observacao[i])
      n_rows <- nrow(tmp)
      
      # PROCESSAMENTO I
      ## A decisão pelo processamento dos dados começa pela verificação de dados faltantes nas coordenadas e
      ## na data.
      na_coord <- max(apply(tmp[c("coord_x", "coord_y")], 2, function (x) sum(is.na(x))))
      na_time <- is.na(tmp$observacao_data)
      n_na_time <- sum(na_time)
      # if (missing$coord == "keep" || missing$coord == "drop" && na_coord < n_rows) {
      if (missing$coord == "keep" && missing$time == "keep" ||
          missing$coord == "drop" && na_coord < n_rows && missing$time == "keep" | missing$time == "drop" ||
          missing$coord == "keep" | missing$coord == "drop" && missing$time == "drop" && n_na_time < n_rows) {
        
        # COLUNAS
        ## Definir as colunas a serem mantidas
        ## As colunas padrão são sempre mantidas.
        ## No caso das colunas adicionais, é possível que algumas não contenham quaisquer dados, assim sendo
        ## ocupadas por 'NA'. Nesse caso, as respectivas colunas são descartadas.  
        in_cols <- colnames(tmp)
        cols <- in_cols[in_cols %in% std_cols]
        extra_cols <- vector()
        if (!missing(variable)) {
          if (length(variable) == 1 && variable == "all") {
          # if (variable == "all") {
            extra_cols <- in_cols[!in_cols %in% std_cols]
            idx_na <- apply(tmp[extra_cols], 2, function (x) all(is.na(x)))
            extra_cols <- extra_cols[!idx_na]
          } else {
            extra_cols <- lapply(variable, function (x) in_cols[grep(paste("^", x, sep = ""), in_cols)])
            extra_cols <- unlist(extra_cols)
            extra_cols <- extra_cols[!extra_cols %in% std_cols]
            idx_na <- apply(tmp[extra_cols], 2, function (x) all(is.na(x)))
            extra_cols <- extra_cols[!idx_na]
          }
        }
        cols <- c(cols, extra_cols)
        tmp <- tmp[, cols]
        unit <- unit[names(unit) %in% cols]
        
        # LINHAS I
        ## Avaliar limpeza das linhas
        tmp_clean <- .cleanRows(obj = tmp, missing = missing, extra_cols = extra_cols)
        n_rows <- nrow(tmp_clean)
        
        # PROCESSAMENTO II
        ## A continuação do processamento dos dados depende das presença de dados após a eliminação de colunas
        ## e linhas com NAs.
        if (n_rows >= 1 && missing(variable) || 
            # length(extra_cols) >= 1 || 
            missing$data == "keep") {
          
          # missing$data == "keep" || missing$coord == "drop" && na_coord < n_rows
          
          # LINHAS II
          ## Definir as linhas a serem mantidas
          if (missing$data == "drop") {
            tmp <- tmp_clean
          }
          
          # TIPO DE DADOS
          ## 'observacao_id', 'sisb_id' e 'ibge_id' precisam estar no formato de caracter para evitar erros
          ## durante o empilhamento das tabelas devido ao tipo de dado.
          ## Nota: esse processamento deve ser feito via Google Sheets.
          tmp$observacao_id <- as.character(tmp$observacao_id)
          if ("sisb_id" %in% colnames(tmp)) {
            tmp$sisb_id <- as.character(tmp$sisb_id)
          }
          if ("ibge_id" %in% colnames(tmp)) {
            tmp$ibge_id <- as.character(tmp$ibge_id)
          }
          # 'coord_precisao' precisa estar no formato numérico ao invés de inteiro
          if ("coord_precisao" %in% colnames(tmp)) {
            tmp$coord_precisao <- as.numeric(tmp$coord_precisao)
          }
          
          # PADRONIZAÇÃO I
          ## Sistema de referência de coordenadas
          ## Primeiro verificar se existem observações com coordenadas e se o SRC deve ser transformado
          na_coord <- max(apply(tmp[c("coord_x", "coord_y")], 2, function (x) sum(is.na(x))))
          if (n_rows > na_coord && !is.null(standardization$crs)) {
            tmp <- .crsTransform(obj = tmp, crs = standardization$crs)
          }
          
          # PADRONIZAÇÃO II
          ## Data de observação
          if (n_rows > na_time && !is.null(standardization$time.format)) {
            tmp <- .formatObservationDate(obj = tmp, time.format = standardization$time.format)
          }
          
          # PADRONIZAÇÃO III
          ## Unidade de medida e número de casas decimais
          if (standardization$units) {
            
            ## Identificar variáveis contínuas (classe 'numeric' e 'integer'), excluíndo variáveis de 
            ## identificação padrão
            id_class <- sapply(tmp, class)
            id_con <- which(id_class %in% c("numeric", "integer") & !names(id_class) %in% std_cols)
            if (length(id_con) >= 1) {
              tmp_stds <- match(cols[id_con], febr_stds$campo_id)
              tmp_stds <- febr_stds[tmp_stds, c("campo_id", "campo_unidade", "campo_precisao")]
              
              ## 1. Se necessário, padronizar unidades de medida
              # idx_unit <- unit[cols[id_con]] != tmp_stds$campo_unidade
              idx_unit <- unit[, cols[id_con]] != tmp_stds$campo_unidade
              if (any(idx_unit)) {
                idx_unit <- colnames(idx_unit)[idx_unit]
                # source <- unit[idx_unit]
                source <- unit[2, idx_unit]
                target <- tmp_stds$campo_unidade[match(idx_unit, tmp_stds$campo_id)]
                
                ## Identificar constante
                k <- lapply(seq_along(source), function (i) {
                  # i <- 2
                  idx <- febr_unit$unidade_origem %in% source[i] + febr_unit$unidade_destino %in% target[i]
                  febr_unit[idx == 2, ] 
                })
                k <- do.call(rbind, k)
                
                ## Processar dados
                tmp[idx_unit] <- mapply(`*`, tmp[idx_unit], k$unidade_constante)
                # unit[idx_unit] <- k$unidade_destino
                unit[2, idx_unit] <- k$unidade_destino
              }
              
              ## 2. Se necessário, padronizar número de casas decimais
              if (standardization$round) {
                tmp[tmp_stds$campo_id] <- 
                  sapply(seq(nrow(tmp_stds)), function (i) 
                    round(x = tmp[tmp_stds$campo_id[i]], digits = tmp_stds$campo_precisao[i]))
              }
            }
          }
          
          # ATTRIBUTOS I
          ## Processar unidades de medida
          unit[2, ] <- as.character(unit[2, names(unit) %in% cols])
          unit[2, ] <- gsub("^-$", "unitless", unit[2, ])
          # unit["observacao_id"] <- c("Identificação da observação", "unitless")
          # dataset_id <- c("Identificação do conjunto de dados", "unitless")
          # https://en.wikipedia.org/wiki/List_of_Unicode_characters
          unit["observacao_id"] <- c("Identifica\u00E7\u00E3o da observa\u00E7\u00E3o", "unitless")
          dataset_id <- c("Identifica\u00E7\u00E3o do conjunto de dados", "unitless")
          unit <- cbind(dataset_id, unit)
          
          # HARMONIZAÇÃO I
          ## Harmonização dos dados das colunas adicionais
          if (harmonization$harmonize) {
            
            ## Harmonização baseada nos níveis dos códigos de identificação
            tmp <- .harmonizeByName(obj = tmp, extra_cols = extra_cols, harmonization = harmonization)
            
          }
          
          # IDENTIFICAÇÃO
          ## Código de identificação do conjunto de dados
          res[[i]] <- cbind(dataset_id = as.character(sheets_keys$ctb[i]), tmp, stringsAsFactors = FALSE)
          
          # ATTRIBUTOS II
          a <- attributes(res[[i]])
          
          ## Adicionar nomes reais
          a$field_name <- as.vector(t(unit)[, 1])
          
          ## Adicionar unidades de medida
          a$field_unit <- as.vector(t(unit)[, 2])
          attributes(res[[i]]) <- a
          
          if (progress) {
            utils::setTxtProgressBar(pb, i)
          }
          
        } else {
          res[[i]] <- data.frame()
          m <- glue::glue("All observations in {dts} are missing data. None will be returned.")
          message(m)
        }
      } else {
        res[[i]] <- data.frame()
        if (na_coord == n_rows) {
          m <- glue::glue("All observations in {dts} are missing coordinates. None will be returned.")  
        } else if (n_na_time == n_rows) {
          m <- glue::glue("All observations in {dts} are missing date. None will be returned.")  
        }
        message(m)
      }
    }
    if (progress) {
      close(pb)
    }
    
    # FINAL
    ## Empilhar conjuntos de dados
    ## Adicionar unidades de medida
    if (stack) {
      res <- .stackTables(obj = res)
    } else if (n == 1) {
      res <- res[[1]]
    }
    
    return (res)
  }

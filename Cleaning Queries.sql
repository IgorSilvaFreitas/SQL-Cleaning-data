-- Checando a base

select *
from cleaning..houses;

-- Transformando valores vazios em NULL

update Cleaning..houses
SET PropertyAddress = NULLIF(PropertyAddress,'')  -- Transforma em NULL todo espaço em branco ('') presente em PropertyAddress
from Cleaning..houses;

-- Alterando a data

ALTER TABLE cleaning..houses
ADD DataVenda Date;

Update Cleaning..houses
SET DataVenda = Convert(Date, SaleDate);

Select Datavenda
from cleaning..houses;

-- Verificando dados faltantes em propertyAdress

       -- Analisando alguma forma de realizar a ação
	   select *
	   from cleaning..houses;
	   -- é possível observar que o ParcelID se repete e o propertyadress é o mesmo para cada parcell, logo podemos utilizar como base para tratar os dados faltantes

	   -- Verificando se todos os vazios em propertyadress tem uma correspondencia de parcelID que possui o endereço
	   Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
	   From cleaning..houses a
	   JOIN cleaning..houses b
	   on a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
	   Where a.PropertyAddress is null;
	   -- Afirmativo, possuem, agora vamos preencher os dados vazios

	   Update a
       SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)  
       From cleaning..houses a
       JOIN cleaning..houses b
	   on a.ParcelID = b.ParcelID
	   AND a.[UniqueID ] <> b.[UniqueID ]
       Where a.PropertyAddress is null;

	   -- Verificando
	   select *
	   from cleaning..houses;



-- Ainda em PropertyAddress, percebe-se que primeiro vem o endereço e depos do delimitador ',' vem a cidade, vamos separá-los

	-- Verificando solução para separar

	Select
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Endereço, -- Charindex verifica a posição do demilitador ','
	substring(PropertyAddress, charindex(',', PropertyAddress)+1, LEN(PropertyAddress)) as Cidade
	from Cleaning..houses;

	-- Update na base de dados
	alter table houses
	add Endereço Nvarchar(255);

	Update houses
	set Endereço = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

	alter table houses
	add Cidade Nvarchar(255);

	Update houses
	set Cidade = substring(PropertyAddress, charindex(',', PropertyAddress)+1, LEN(PropertyAddress));

	select Endereço, Cidade
	from houses;


-- OwnerAddress possui o mesmo problema, vamos aproveitar o fato de apenas a vírgular ser o delimitador e utilizar uma função mais prática

	-- Vamos verificar se realmente irá funcionar
	Select
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),        -- A ordem parece inversa, 3,2,1, pois a função ocorre de trás pra frente
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
	From houses;

	--	Agora vamos fazer update na base

	alter table houses
	add EndereçoDono Nvarchar(255);

	alter table houses
	add CidadeDono Nvarchar(255);

	alter table houses
	add EstadoDono Nvarchar(255);

	Update houses
	set EndereçoDono = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3);

	Update houses
	set CidadeDono = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2);

	Update houses
	set EstadoDono = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

	select EndereçoDono, CidadeDono, EstadoDono
	from houses;



-- Avaliando SoldAsVacant percebemos que possui respostas como No e N, Yes e Y, então vamos padronizar

	-- Verificando
	Select distinct(SoldAsVacant), count(SoldAsVacant) as sum
	from houses
	Group by SoldAsVacant
	order by sum;

	-- Vamos descobrir como padronizar
	Select SoldAsVacant,
	Case when SoldAsVacant = 'Y' then 'Yes'
		 when SoldAsVacant = 'N' then 'No'
		 else SoldAsVacant
		 end
	from houses;

	-- Hora do update
	Update houses
	set SoldAsVacant = Case when SoldAsVacant = 'Y' then 'Yes'
							when SoldAsVacant = 'N' then 'No'
							else SoldAsVacant
							end

	Select distinct(SoldAsVacant), count(SoldAsVacant) as sum
	from houses
	Group by SoldAsVacant
	order by sum;


--	Remover dados duplicados

	-- Analisando duplicatas
	With rownumcte as (
	select *,
	row_number() over(partition by ParcelID,
								   PropertyAddress,
								   SalePrice,
								   SaleDate,
								   LegalReference
								   order by UniqueID) row_num -- Escolhemos uma quantidade razoavel de colunas e ordenamos por UniqueID, assim, sempre que uniqueID for diferente, porém as outras variáveis forem iguais, row_num recebe valor 2
	from houses)

	-- agora vamos verificar todas as duplicatas
	select *
	from rownumcte
	where row_num > 1;

	-- A remoção deve ser feita com cautela e há de se analisar a real necessidade de exlcuir

	-- Delete dup
	-- from(select *,
		--   duprank = row_number() over(partition by ParcelID,
	--							   PropertyAddress,
	--							   SalePrice,
	--							   SaleDate,
	--							   LegalReference
	--							   order by UniqueID)
	-- from houses) as dup
	-- where dup > 1



-- Removendo coluna

alter table houses
add row_num int;

alter table houses
drop column row_num;

	-- Podemos excluir as colunas as quais modificamos anteriormente

	-- alter table houses
	-- drop clumn SaleDate, PropertyAddress, OwnerAddress;



--Covid 19 Data Exploration 

--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

SELECT * 
FROM dbo.['Covid Deaths$'] 
ORDER BY 3,4

--SELECT * 
--FROM dbo.['Covid Vaccinations$']
--ORDER BY 3,4

SELECT *
FROM dbo.['Covid Deaths$']
Where continent is not null 
order by 3,4

-- Let's Select the Data we shall start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.['Covid Deaths$']
ORDER BY 1,2

-- Let's compare the Total Deaths to Total Cases
-- This will give us the probability of death when COVID is contracted per country (per day)

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
FROM dbo.['Covid Deaths$']
ORDER BY 1,2

--Now let's see the probability of dying if you contract COVID in your country (per day)

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
FROM dbo.['Covid Deaths$']
WHERE location like '%Kenya%'
ORDER BY 1,2

-- Global Death Percentage based on the number of cases

SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as bigint)) as Total_deaths, SUM(cast(new_deaths as bigint)) / SUM(new_cases)*100 as DeathPercentage
FROM dbo.['Covid Deaths$']
--WHERE location like '%Kenya%'
WHERE continent is not null
ORDER BY 1,2

-- Kenyan Death Percentage based on the number of cases

SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as bigint)) as Total_deaths, SUM(cast(new_deaths as bigint)) / SUM(new_cases)*100 as DeathPercentage
FROM dbo.['Covid Deaths$']
WHERE location like '%Kenya%'
--WHERE continent is not null
ORDER BY 1,2

-- Let's compare the Population to Total Cases
-- This will show the percentage of population infected with Covid (per day as a cumulative percentage)

SELECT location, date, total_cases, population, (total_cases / population)*100 as InfectedPercentage
FROM dbo.['Covid Deaths$']
--WHERE location like '%Kenya%'
ORDER BY 1,2

--Let's now compare the countries
--Countries with the highest infection rate per population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount, MAX((cast(total_deaths as int)/population))*100 as PercentPopulationDead
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC 

-- Let's view the data by continent
-- Let's see which continent had the most to the least deaths as a percantage of their population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount, MAX((cast(total_deaths as int)/population))*100 as PercentPopulationDead
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY continent
ORDER BY PercentPopulationDead DESC 

-- Global deaths as a percentage of the cases reported per day
-- This would make a interactive good line graph, x-axis date, y-axis Death Percentages

SELECT date, SUM(total_cases), SUM(cast(total_deaths as int)), SUM(cast(total_deaths as int))/SUM(total_cases)*100 as GlobalDeathPercentage
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- VACCINATIONS DATA

SELECT * FROM dbo.['Covid Vaccinations$']

-- Let's join the Deaths and Vaccinations Tables

SELECT * 
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date

--Let's compare Total Vaccinations to the Population
--This is for good for a two line graph x-axis date, y-axis Population and Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Now let's view the %age of the population that has received at least one Covid Vaccine as a Rolling Value per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Now let's use a CTE to perform a calculation on PARTITION BY in the previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- Now let's use a TEMP TABLE to perform a calculation on PARTITION BY in the previous query
-- Remember to add DROP TABLE to the beginning to avoid errors if you want to execute the query with some changes later on

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
) 

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- CREATE A VIEW TO STORE DATA FOR VISUALIZATIONS WHICH WILL BE MADE LATER
-- Vaccinations 

CREATE VIEW PercentPopulationVaccinated 
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
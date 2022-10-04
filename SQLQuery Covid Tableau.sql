-- Queries used for Tableau Project

-- 1 
-- Global Death Percentage based on the number of cases

SELECT SUM(new_cases) as Total_cases, SUM(cast(new_deaths as bigint)) as Total_deaths, SUM(cast(new_deaths as bigint)) / SUM(new_cases)*100 as DeathPercentage
FROM dbo.['Covid Deaths$']
--WHERE location like '%Kenya%'
WHERE continent is not null
ORDER BY 1,2

-- 2 
-- Total Death Count Per Continent

SELECT location, SUM(cast(new_deaths as bigint)) as TotalDeathCount
FROM dbo.['Covid Deaths$']
WHERE continent is null 
AND location not in ('World', 'European Union', 'International', 'High Income', 'Upper middle income', 'Lower middle income','Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3
--Countries with the highest infection rate per population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--4
--Countries with the highest infection rate per population per day

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY location, population, date
ORDER BY PercentPopulationInfected DESC

-- 5
-- Global deaths by date as a percentage of the cases reported per continent per day 

SELECT continent, date, SUM(total_cases) as TotalCases, SUM(cast(total_deaths as int)) as TotalDeaths, SUM(cast(total_deaths as int))/SUM(total_cases)*100 as GlobalDeathPercentage
FROM dbo.['Covid Deaths$']
WHERE continent is not null
GROUP BY continent, date
ORDER BY 1,2


-- 6
-- Let's compare Total Vaccinations to the Population by date

-- First Join the  deaths and vaccinations tables
SELECT * 
FROM dbo.['Covid Deaths$'] dea
JOIN dbo.['Covid Vaccinations$'] vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Then compare Total Vaccinations to the Population
-- %age of the population that has received at least one Covid Vaccine as a Rolling Value per day per continent

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
SELECT *, (RollingPeopleVaccinated/population)*100 as Vaccination_Percentage
FROM PopvsVac



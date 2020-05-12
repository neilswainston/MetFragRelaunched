package de.ipbhalle.metfraglib.peaklistreader;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;

import de.ipbhalle.metfraglib.list.DefaultPeakList;
import de.ipbhalle.metfraglib.list.SortedTandemMassPeakList;
import de.ipbhalle.metfraglib.parameter.Constants;
import de.ipbhalle.metfraglib.parameter.VariableNames;
import de.ipbhalle.metfraglib.peak.TandemMassPeak;
import de.ipbhalle.metfraglib.settings.Settings;

public class FilteredTandemMassPeakListReader extends AbstractPeakListReader {
	
	protected double minimumAbsolutePeakIntensity;
	protected byte precursorAdductTypeIndex;
	
	public FilteredTandemMassPeakListReader(Settings settings) {
		super(settings);
		this.minimumAbsolutePeakIntensity = (Double)settings.get(VariableNames.MINIMUM_ABSOLUTE_PEAK_INTENSITY_NAME);
		this.precursorAdductTypeIndex = (byte)Constants.ADDUCT_NOMINAL_MASSES.indexOf((Integer)settings.get(VariableNames.PRECURSOR_ION_MODE_NAME));
	}

	public DefaultPeakList read() {
		int numberMaximumPeaksUsed = (Integer)settings.get(VariableNames.NUMBER_MAXIMUM_PEAKS_USED_NAME);
		SortedTandemMassPeakList peakList = null;
		String data = (String)this.settings.get(VariableNames.PEAK_LIST_PATH_NAME);
		
		Reader dbReader = null;
		
		try {
			final File file = new File(data);
			dbReader = new FileReader(file);
		}
		catch(IOException e) {
			dbReader = new StringReader(data);
		}
		
		try {
			java.io.BufferedReader breader = new java.io.BufferedReader(dbReader);
			peakList = new SortedTandemMassPeakList((Double)this.settings.get(VariableNames.PRECURSOR_NEUTRAL_MASS_NAME));
			String line = "";
			while((line = breader.readLine()) != null) {
				line = line.trim();
				if(line.startsWith("#") || line.length() == 0) continue;
				String[] tmp = line.split("\\s+");
				double currentMass;
				double currentIntensity;
				try {
					currentMass = Double.parseDouble(tmp[0].trim().replaceAll("^-*", ""));
					currentIntensity = Double.parseDouble(tmp[1].trim());
				} catch(Exception e) {
					breader.close();
					throw new IOException();
				}
				/*
				 * filtering step
				 */
				if(currentMass >= ((Double)settings.get(VariableNames.PRECURSOR_NEUTRAL_MASS_NAME) - 5.0 + Constants.ADDUCT_MASSES.get(this.precursorAdductTypeIndex))) 
					continue;
				if(currentIntensity < this.minimumAbsolutePeakIntensity) 
					continue;
				/*
				 * if filters passed add the current peak
				 */
				peakList.addElement(new TandemMassPeak(currentMass, currentIntensity));
			}
			breader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		for(int i = 0; i < peakList.getNumberElements(); i++)
			peakList.getElement(i).setID(i);
		this.deleteByMaximumNumberPeaksUsed(numberMaximumPeaksUsed, peakList);
		peakList.calculateRelativeIntensities(Constants.DEFAULT_MAXIMUM_RELATIVE_INTENSITY);
		return peakList;
	}
	
}

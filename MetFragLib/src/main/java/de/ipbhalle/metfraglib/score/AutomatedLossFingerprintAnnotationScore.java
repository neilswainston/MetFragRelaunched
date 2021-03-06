package de.ipbhalle.metfraglib.score;

import de.ipbhalle.metfraglib.FastBitArray;
import de.ipbhalle.metfraglib.interfaces.ICandidate;
import de.ipbhalle.metfraglib.interfaces.IMatch;
import de.ipbhalle.metfraglib.match.MassFingerprintMatch;
import de.ipbhalle.metfraglib.parameter.VariableNames;
import de.ipbhalle.metfraglib.settings.Settings;
import de.ipbhalle.metfraglib.substructure.MassToFingerprintGroupList;
import de.ipbhalle.metfraglib.substructure.MassToFingerprintGroupListCollection;

public class AutomatedLossFingerprintAnnotationScore extends AbstractScore {

	protected ICandidate candidate;
	
	public AutomatedLossFingerprintAnnotationScore(Settings settings) {
		super(settings);
		this.optimalValues = new double[1];
		this.optimalValues[0] = 0.0;
		this.candidate = (ICandidate)settings.get(VariableNames.CANDIDATE_NAME);
		this.hasInterimResults = true;
	}
	
	public void calculate() {
		this.value = 0.0;
		this.calculationFinished = true;
	}

	public void setOptimalValues(double[] values) {
		this.optimalValues[0] = values[0];
	}
	
	/**
	 * collects the background fingerprints
	 */
	public Double[] calculateSingleMatch(IMatch match) {
		return new Double[] {0.0, null};
	}
	
	@Override
	public void singlePostCalculate() {
		this.value = 0.0;
		MassToFingerprintGroupListCollection lossToFingerprintGroupListCollection = (MassToFingerprintGroupListCollection)this.settings.get(VariableNames.LOSS_TO_FINGERPRINT_GROUP_LIST_COLLECTION_NAME);
		// all losses found in peak list
		java.util.LinkedList<?> lossMassesFoundInPeakList = (java.util.LinkedList<?>)((java.util.LinkedList<?>)this.settings.get(VariableNames.LOSS_MASSES_FOUND_PEAKLIST_NAME)).clone();
		int matches = 0;
		Double mzppm = (Double)settings.get(VariableNames.RELATIVE_MASS_DEVIATION_NAME);
		Double mzabs = (Double)settings.get(VariableNames.ABSOLUTE_MASS_DEVIATION_NAME);
		// get match list of the current candidate
		java.util.ArrayList<?> lossMatchlist = (java.util.ArrayList<?>)this.candidate.getProperty("LossMatchList");
		java.util.ArrayList<Double> matchMasses = new java.util.ArrayList<Double>();
		java.util.ArrayList<Double> matchProb = new java.util.ArrayList<Double>();
		java.util.ArrayList<Integer> matchType = new java.util.ArrayList<Integer>(); // found - 1; non-found - 2 (fp="0"); alpha - 3; beta - 4
		// get foreground fingerprint observations (m_f_observed)
		for(int i = 0; i < lossMatchlist.size(); i++) {
			// get f_m_observed
			MassFingerprintMatch currentMatch = (MassFingerprintMatch)lossMatchlist.get(i);
			lossMassesFoundInPeakList.remove(lossMassesFoundInPeakList.indexOf(currentMatch.getMass()));
			MassToFingerprintGroupList lossToFingerprintGroupList = lossToFingerprintGroupListCollection.getElementByPeak(currentMatch.getMass(), mzppm, mzabs);
			//MassFingerprintMatch currentMatch = this.getMatchByMass(matchlist, currentMass);
			FastBitArray currentFingerprint = new FastBitArray(currentMatch.getFingerprint());
			// ToDo: at this stage try to check all fragments not only the best one
			// (p(m,f) + alpha) / sum_F(p(m,f)) + |F| * alpha
			double matching_prob = lossToFingerprintGroupList.getMatchingProbability(currentFingerprint);
			if(matching_prob != 0.0) { // if probability of current fingerprint is non-zero, it was observed in the training
				matches++;
				this.value += Math.log(matching_prob);
				matchProb.add(matching_prob);
				if(currentFingerprint.getSize() != 1) matchType.add(1); // if valid fingerprint
				else matchType.add(2); // if size of fingerprint is 1 then it's the dummy fingerprint
				matchMasses.add(currentMatch.getMass()); 
			}
			else {
				// if not type 1 or type 2
				matchMasses.add(currentMatch.getMass());
				if(currentFingerprint.getSize() != 1) {
					this.value += Math.log(lossToFingerprintGroupList.getAlphaProb());
					matchProb.add(lossToFingerprintGroupList.getAlphaProb());
					matchType.add(3);
				}
				else {
					this.value += Math.log(lossToFingerprintGroupList.getBetaProb());
					matchProb.add(lossToFingerprintGroupList.getBetaProb());
					matchType.add(4);
				}
			}
		}
		if(lossToFingerprintGroupListCollection.getNumberElements() == 0) this.value = 0.0;
		
		this.candidate.setProperty("AutomatedLossFingerprintAnnotationScore_Matches", matches);
		this.candidate.setProperty("AutomatedLossFingerprintAnnotationScore", this.value);
		this.candidate.setProperty("AutomatedLossFingerprintAnnotationScore_Probtypes", this.getProbTypeString(matchProb, matchType, matchMasses));
		this.candidate.removeProperty("LossMatchList");
	}

	public String getProbTypeString(java.util.ArrayList<Double> matchProb, java.util.ArrayList<Integer> matchType, java.util.ArrayList<Double> matchMasses) {
		if(matchProb.size() == 0) return "NA";
		StringBuilder string = new StringBuilder();
		if(matchProb.size() >= 1) {
			string.append(matchType.get(0));
			string.append(":");
			string.append(matchProb.get(0));
			string.append(":");
			string.append(matchMasses.get(0));
		}
		for(int i = 1; i < matchProb.size(); i++) {
			string.append(";");
			string.append(matchType.get(i));
			string.append(":");
			string.append(matchProb.get(i));
			string.append(":");
			string.append(matchMasses.get(i));
		}
		return string.toString();
	}
	
	public MassFingerprintMatch getMatchByMass(java.util.ArrayList<?> matches, Double peakMass) {
		for(int i = 0; i < matches.size(); i++) {
			MassFingerprintMatch match = (MassFingerprintMatch)matches.get(i);
			if(match.getMass().equals(peakMass)) 
				return match;
		}
		return null;
	}

	@Override
	public String getOptimalValuesToString() {
		return this.candidate.hasDefinedProperty("AutomatedLossFingerprintAnnotationScore_Probtypes") ? (String)this.candidate.getProperty("AutomatedLossFingerprintAnnotationScore_Probtypes") : "NA";
	}
	
	@Override
	public void nullify() {
		super.nullify();
	}

	public boolean isBetterValue(double value) {
		return value > this.value ? true : false;
	}
}

@IsTest
public class Random {

	public String string() {
		return string(8);
	}


	public String string(Integer length) {
		String result = '';

		for(Integer i=0; i<length; i++) {
			Integer pos = integer(25);
			result += 'abcdefghijklmnopqrstuvwxyz'.substring(pos, pos+1);
		}

		return result;
	}


	public Decimal decimal(Decimal first, Decimal last) {
		return Math.random() * ((last - first) + 1) + first;
	}


	public Decimal decimal(Integer max) {
		return decimal(0, max);
	}


	public Integer integer(Integer first, Integer last) {
		return Math.floor(Math.random() * ((last - first) + 1) + first).intValue();
	}


	public Integer integer(Integer max) {
		return integer(0, max);
	}


	public Boolean boolean() {
		return integer(0, 1) == 0;
	}


	public Object value(List<Object> values) {
		return values.get(integer(values.size()-1));
	}
}